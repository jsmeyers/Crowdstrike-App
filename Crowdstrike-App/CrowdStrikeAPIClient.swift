//
//  CrowdStrikeAPIClient.swift
//  Crowdstrike-App
//

import Foundation

// MARK: - API Client

actor CrowdStrikeAPIClient {
    
    static let shared = CrowdStrikeAPIClient()
    
    private var configuration: AppConfiguration = .default
    private var accessToken: String?
    private var tokenExpiration: Date?
    private var tokenScopes: [String] = []
    
    private var tokenRefreshTask: Task<Void, Error>?
    private var cachedURLSession: URLSession?
    private var proxyCredentials: (username: String, password: String)?
    
    private let keychain = KeychainManager.shared
    
    private var shouldLogResponses: Bool = false
    
    private init() {}
    
    func updateConfiguration(_ config: AppConfiguration) async {
        self.configuration = config
        self.shouldLogResponses = config.isDebugModeEnabled
        accessToken = nil
        tokenExpiration = nil
        cachedURLSession?.finishTasksAndInvalidate()
        cachedURLSession = nil
        
        if config.proxy.isEnabled && config.proxy.requiresAuth {
            self.proxyCredentials = try? await keychain.retrieveProxyCredentials()
        } else {
            self.proxyCredentials = nil
        }
    }
    
    func getConfiguration() -> AppConfiguration {
        return configuration
    }
    
    func setLoggingEnabled(_ enabled: Bool) {
        self.shouldLogResponses = enabled
    }
    
    private func createURLSession() -> URLSession {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.requestTimeout
        sessionConfig.timeoutIntervalForResource = configuration.requestTimeout * 2
        
        if configuration.proxy.isEnabled && !configuration.proxy.host.isEmpty {
            let proxyHost = configuration.proxy.host
            let proxyPort = configuration.proxy.port
            
            var proxyDict: [String: Any] = [
                "HTTPEnable": 1,
                "HTTPProxy": proxyHost,
                "HTTPPort": proxyPort,
                "HTTPSEnable": 1,
                "HTTPSProxy": proxyHost,
                "HTTPSPort": proxyPort
            ]
            
            if configuration.proxy.requiresAuth, let creds = proxyCredentials {
                proxyDict["HTTPUser"] = creds.username
                proxyDict["HTTPPass"] = creds.password
            }
            
            sessionConfig.connectionProxyDictionary = proxyDict
        }
        
        return URLSession(configuration: sessionConfig)
    }
    
    private func urlSession() -> URLSession {
        if let cachedURLSession { return cachedURLSession }
        let new = createURLSession()
        cachedURLSession = new
        return new
    }
    
    func setProxyCredentials(username: String, password: String) async throws {
        try await keychain.storeProxyCredentials(username: username, password: password)
        self.proxyCredentials = (username, password)
        cachedURLSession?.finishTasksAndInvalidate()
        cachedURLSession = nil
    }
    
    func clearProxyCredentials() async throws {
        try await keychain.deleteProxyCredentials()
        self.proxyCredentials = nil
        cachedURLSession?.finishTasksAndInvalidate()
        cachedURLSession = nil
    }
    
    func clearAuthState() {
        accessToken = nil
        tokenExpiration = nil
        tokenScopes = []
        tokenRefreshTask?.cancel()
        tokenRefreshTask = nil
    }
    
    private func authorizationHeader() throws -> String {
        guard let token = accessToken, !token.isEmpty else {
            throw APIError.notAuthenticated
        }
        return "Bearer \(token)"
    }
    
    private func encodeFQLFilter(_ filter: String) -> String {
        guard let encoded = filter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return filter
        }
        return encoded
            .replacingOccurrences(of: "+", with: "%2B")
            .replacingOccurrences(of: "=", with: "%3D")
    }
    
    private func logResponse(_ data: Data, label: String) {
        guard shouldLogResponses else { return }
        
        print("\n" + String(repeating: "=", count: 80))
        print("=== \(label) ===")
        print(String(repeating: "=", count: 80))
        
        if let jsonString = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let redactedJson = Self.redactSensitive(jsonString) as? [String: Any],
           let prettyData = try? JSONSerialization.data(withJSONObject: redactedJson, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            print(prettyString)
        } else if let rawString = String(data: data, encoding: .utf8) {
            print(Self.redactSensitiveString(rawString))
        } else {
            print("[Unable to decode response data]")
        }
        
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    private nonisolated static func redactSensitive(_ json: Any) -> Any {
        guard let dict = json as? [String: Any] else { return json }
        var result = dict
        for key in dict.keys {
            let lowercased = key.lowercased()
            if lowercased.contains("access_token") || lowercased.contains("token") || lowercased.contains("secret") {
                if let value = dict[key] as? String, !value.isEmpty {
                    result[key] = String(value.prefix(8)) + "***REDACTED***"
                }
            } else if let value = dict[key] {
                result[key] = redactSensitive(value)
            }
        }
        return result
    }
    
    private nonisolated static func redactSensitiveString(_ string: String) -> String {
        var result = string
        result = result.replacingOccurrences(
            of: "client_secret=[^\u0026]+",
            with: "client_secret=***REDACTED***",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "\"access_token\"\\s*:\\s*\"[^\"]+\"",
            with: "\"access_token\":\"***REDACTED***\"",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "Bearer\\s+[A-Za-z0-9\\-\\._~+\\/]+=*",
            with: "Bearer ***REDACTED***",
            options: .regularExpression
        )
        return result
    }
    
    private func logResponseErrors(_ errors: [APIErrorDetail]?, context: String) {
        guard let errors, !errors.isEmpty else { return }
        for error in errors {
            print("⚠️ API Error [\(context)] code=\(error.code ?? -1) id=\(error.id ?? "nil"): \(error.message ?? "no message")")
        }
    }
    
    func authenticate(clientId: String, clientSecret: String) async throws {
        var request = URLRequest(url: URL(string: "\(configuration.baseURLWithProtocol)/oauth2/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = configuration.connectionTimeout
        
        let encodedClientId = clientId.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? clientId
        let encodedSecret = clientSecret.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        ) ?? clientSecret
        let body = "client_id=\(encodedClientId)&client_secret=\(encodedSecret)"
        request.httpBody = body.data(using: .utf8)
        
        let session = urlSession()
        let (data, response) = try await session.data(for: request)
        
        // Intentionally do not log the OAuth token response body, even in debug mode,
        // to avoid leaking access tokens to the device console. Error responses are
        // surfaced through the thrown error below.
        if shouldLogResponses {
            print("OAuth token response received (body redacted for security)")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.authenticationFailed(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        
        guard let token = tokenResponse.accessToken, !token.isEmpty else {
            throw APIError.authenticationFailed(statusCode: httpResponse.statusCode, message: "No access token in response")
        }
        
        let expiresIn = tokenResponse.expiresIn ?? 1800
        self.accessToken = token
        self.tokenExpiration = Date().addingTimeInterval(TimeInterval(expiresIn - 60))
        self.tokenScopes = tokenResponse.scope?.split(separator: " ").map(String.init) ?? []
        
        try await keychain.storeCredentials(clientId: clientId, clientSecret: clientSecret)
        try await keychain.deleteBearerToken()
    }
    
    func setBearerToken(_ token: String) async throws {
        self.accessToken = token
        self.tokenExpiration = Date().addingTimeInterval(3600)
        self.tokenScopes = [] // Bearer tokens don't return scopes via this flow
        try await keychain.storeBearerToken(token)
        try await keychain.deleteCredentials()
    }
    
    func isAuthenticated() -> Bool {
        guard let token = accessToken, let expiration = tokenExpiration else { return false }
        return !token.isEmpty && Date() < expiration
    }
    
    func getStoredBearerToken() async -> String? {
        return try? await keychain.retrieveBearerToken()
    }
    
    private func refreshToken() async throws {
        switch configuration.authMethod {
        case .oauth:
            if let (clientId, clientSecret) = try? await keychain.retrieveCredentials() {
                try await authenticate(clientId: clientId, clientSecret: clientSecret)
                self.shouldLogResponses = configuration.isDebugModeEnabled
            } else {
                throw APIError.notAuthenticated
            }
        case .bearerToken:
            if let token = try? await keychain.retrieveBearerToken() {
                self.accessToken = token
                self.tokenExpiration = Date().addingTimeInterval(3600)
            } else {
                throw APIError.notAuthenticated
            }
        }
    }
    
    private func ensureValidToken() async throws {
        if isAuthenticated() { return }
        
        if let existing = tokenRefreshTask {
            try await existing.value
            return
        }
        
        let task = Task<Void, Error> { [weak self] in
            guard let self else { throw APIError.notAuthenticated }
            try await self.refreshToken()
        }
        tokenRefreshTask = task
        defer { tokenRefreshTask = nil }
        try await task.value
    }
    
    // MARK: - Token Scopes Check
    
    /// Checks if the current token has the necessary scopes for Hosts and Alerts,
    /// and verifies it doesn't have excessive permissions (principle of least privilege).
    func checkTokenScopes() async -> (canReadHosts: Bool, canReadAlerts: Bool, errorMessage: String?) {
        try? await ensureValidToken()
        guard isAuthenticated() else {
            return (false, false, "Not authenticated. Please log in.")
        }
        
        let session = urlSession()
        
        // Check Hosts (Device API: Read)
        let hostsUrl = URL(string: "\(configuration.baseURLWithProtocol)/devices/queries/devices/v1?limit=1")!
        var hostsRequest = URLRequest(url: hostsUrl)
        hostsRequest.setValue(try? authorizationHeader(), forHTTPHeaderField: "Authorization")
        hostsRequest.timeoutInterval = configuration.connectionTimeout
        
        var canReadHosts = false
        if let (_, response) = try? await session.data(for: hostsRequest),
           let httpResponse = response as? HTTPURLResponse {
            canReadHosts = httpResponse.statusCode == 200
        }
        
        // Check Alerts (Alerts API: Read)
        let alertsUrl = URL(string: "\(configuration.baseURLWithProtocol)/alerts/queries/alerts/v2?limit=1")!
        var alertsRequest = URLRequest(url: alertsUrl)
        alertsRequest.setValue(try? authorizationHeader(), forHTTPHeaderField: "Authorization")
        alertsRequest.timeoutInterval = configuration.connectionTimeout
        
        var canReadAlerts = false
        if let (_, response) = try? await session.data(for: alertsRequest),
           let httpResponse = response as? HTTPURLResponse {
            canReadAlerts = httpResponse.statusCode == 200
        }
        
        // Check for too many permissions (least privilege)
        var scopeWarning: String? = nil
        if !tokenScopes.isEmpty {
            // Define the allowed scopes for this app.
            let allowedScopes: Set<String> = ["hosts.read", "alerts.read", "device.read", "oauth", "oauth2"]
            let unexpectedScopes = tokenScopes.filter { !allowedScopes.contains($0.lowercased()) }
            if !unexpectedScopes.isEmpty {
                scopeWarning = "Security Warning: Your API token has more permissions than required. Unexpected scopes found: \(unexpectedScopes.joined(separator: ", ")). Please restrict the API client to only 'Hosts: Read' and 'Alerts: Read'."
            }
        }
        
        let errorMessage: String?
        if !canReadHosts || !canReadAlerts {
            errorMessage = "Your API token is missing required permissions. Please ensure 'Device API: Read' and 'Alerts API: Read' scopes are enabled in CrowdStrike."
        } else if let scopeWarning {
            errorMessage = scopeWarning
        } else {
            errorMessage = nil
        }
        
        return (canReadHosts, canReadAlerts, errorMessage)
    }
    
    private func searchHostsPage(query: String?, offset: Int?, limit: Int) async throws -> (hostIds: [String], nextOffset: Int?, total: Int?) {
        try await ensureValidToken()
        
        var urlString = "\(configuration.baseURLWithProtocol)/devices/queries/devices/v1?limit=\(limit)"
        
        if let query = query, !query.isEmpty {
            urlString += "&filter=\(encodeFQLFilter(query))"
        }
        if let offset = offset {
            urlString += "&offset=\(offset)"
        }
        
        guard let url = URL(string: urlString) else { throw APIError.invalidResponse }
        
        var request = URLRequest(url: url)
        request.setValue(try authorizationHeader(), forHTTPHeaderField: "Authorization")
        request.timeoutInterval = configuration.requestTimeout
        
        let session = urlSession()
        let (data, response) = try await session.data(for: request)
        
        logResponse(data, label: "Host Search Response")
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                message: String(data: data, encoding: .utf8) ?? "Unknown error"
            )
        }
        
        let hostsResponse = try JSONDecoder().decode(HostsResponse.self, from: data)
        logResponseErrors(hostsResponse.errors, context: "Host Search")
        
        let ids = hostsResponse.resources ?? []
        let total = hostsResponse.meta?.pagination?.total ?? 0
        let apiOffset = hostsResponse.meta?.pagination?.offset ?? (offset ?? 0)
        
        // Manually advance the offset if the API returned the current offset instead of the next one
        let nextOffset: Int? = ids.isEmpty ? nil : (apiOffset > (offset ?? 0) ? apiOffset : (offset ?? 0) + ids.count)
        let shouldBreak = nextOffset == nil || ids.isEmpty || (total > 0 && (nextOffset ?? 0) >= total)
        
        return (ids, shouldBreak ? nil : nextOffset, total)
    }
    
    private func getHostDetailsBatch(hostIds: [String]) async throws -> [Host] {
        try await ensureValidToken()
        guard !hostIds.isEmpty else { return [] }
        
        var urlComponents = URLComponents(string: "\(configuration.baseURLWithProtocol)/devices/entities/devices/v2")!
        urlComponents.queryItems = hostIds.map { URLQueryItem(name: "ids", value: $0) }
        
        guard let url = urlComponents.url else { throw APIError.invalidResponse }
        
        var request = URLRequest(url: url)
        request.setValue(try authorizationHeader(), forHTTPHeaderField: "Authorization")
        request.timeoutInterval = configuration.requestTimeout
        
        let session = urlSession()
        let (data, response) = try await session.data(for: request)
        
        logResponse(data, label: "Host Details Response (\(hostIds.count) hosts)")
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                message: String(data: data, encoding: .utf8) ?? "Unknown error"
            )
        }
        
        logResponseErrors((try? JSONDecoder().decode(HostDetailsResponse.self, from: data).errors), context: "Host Details")
        
        do {
            return try JSONDecoder().decode(HostDetailsResponse.self, from: data).resources ?? []
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    func searchAndRetrieveHostsWithProgress(query: String?, progressHandler: @escaping (Int, Int) -> Void) async throws -> [Host] {
        try await ensureValidToken()
        
        var countUrlString = "\(configuration.baseURLWithProtocol)/devices/queries/devices/v1?limit=1"
        if let query = query, !query.isEmpty {
            countUrlString += "&filter=\(encodeFQLFilter(query))"
        }
        
        guard let countUrl = URL(string: countUrlString) else { throw APIError.invalidResponse }
        var countRequest = URLRequest(url: countUrl)
        countRequest.setValue(try authorizationHeader(), forHTTPHeaderField: "Authorization")
        
        let session = urlSession()
        let (countData, countResponse) = try await session.data(for: countRequest)
        
        guard let httpResponse = countResponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (countResponse as? HTTPURLResponse)?.statusCode ?? 0
            let message = String(data: countData, encoding: .utf8) ?? "Unknown error"
            throw APIError.requestFailed(statusCode: statusCode, message: message)
        }
        
        let initialResponse = try JSONDecoder().decode(HostsResponse.self, from: countData)
        logResponseErrors(initialResponse.errors, context: "Host Count")
        let totalCount = initialResponse.meta?.pagination?.total ?? 0
        
        print("Total host count: \(totalCount)")
        progressHandler(0, totalCount)
        
        if totalCount == 0 { return [] }
        
        var allHostIds: [String] = []
        var currentOffset: Int? = nil
        let limit = 500
        
        let halfTotal = totalCount / 2
        
        while true {
            try Task.checkCancellation()
            let (hostIds, nextOffset, _) = try await searchHostsPage(query: query, offset: currentOffset, limit: limit)
            allHostIds.append(contentsOf: hostIds)
            currentOffset = nextOffset
            progressHandler(min(allHostIds.count, halfTotal), totalCount)
            
            if nextOffset == nil || hostIds.isEmpty {
                break
            }
        }
        
        print("Total host IDs fetched: \(allHostIds.count)")
        
        var allHosts: [Host] = []
        let batchSize = 100
        let detailDenominator = max(allHostIds.count, 1)
        
        for i in stride(from: 0, to: allHostIds.count, by: batchSize) {
            try Task.checkCancellation()
            let batchEnd = min(i + batchSize, allHostIds.count)
            let batchIds = Array(allHostIds[i..<batchEnd])
            
            let hosts = try await getHostDetailsBatch(hostIds: batchIds)
            allHosts.append(contentsOf: hosts)
            let detailProgress = halfTotal + Int((Double(batchEnd) / Double(detailDenominator)) * Double(halfTotal))
            progressHandler(detailProgress, totalCount)
        }
        
        print("Total hosts retrieved: \(allHosts.count)")
        return allHosts
    }
    
    private func queryAlertIdsPage(filterString: String, limit: Int, offset: Int?) async throws -> (ids: [String], nextOffset: Int?, total: Int?) {
        try await ensureValidToken()
        
        var urlString = "\(configuration.baseURLWithProtocol)/alerts/queries/alerts/v2?limit=\(limit)&filter=\(encodeFQLFilter(filterString))"
        if let offset {
            urlString += "&offset=\(offset)"
        }
        
        guard let url = URL(string: urlString) else { throw APIError.invalidResponse }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(try authorizationHeader(), forHTTPHeaderField: "Authorization")
        request.timeoutInterval = configuration.requestTimeout
        
        let session = urlSession()
        let (data, response) = try await session.data(for: request)
        
        logResponse(data, label: "Alerts Query Response (offset=\(offset ?? 0))")
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                message: String(data: data, encoding: .utf8) ?? "Unknown error"
            )
        }
        
        let alertsResponse = try JSONDecoder().decode(AlertsResponse.self, from: data)
        logResponseErrors(alertsResponse.errors, context: "Alerts Query")
        
        let ids = alertsResponse.resources ?? []
        let total = alertsResponse.meta?.pagination?.total ?? 0
        let apiOffset = alertsResponse.meta?.pagination?.offset ?? (offset ?? 0)
        
        // Manually advance the offset if the API returned the current offset instead of the next one
        let nextOffset: Int? = ids.isEmpty ? nil : (apiOffset > (offset ?? 0) ? apiOffset : (offset ?? 0) + ids.count)
        let shouldBreak = nextOffset == nil || ids.isEmpty || (total > 0 && (nextOffset ?? 0) >= total)
        
        return (ids, shouldBreak ? nil : nextOffset, total)
    }
    
    func fetchAlerts(limit: Int = 500, minSeverity: Int? = 55, since: Date? = nil, filterThirdParty: Bool = true, progressHandler: @escaping (Int, Int) -> Void = { _, _ in }) async throws -> [Alert] {
        try await ensureValidToken()
        
        var filters: [String] = []
        
        if let minSeverity {
            filters.append("severity:>=\(minSeverity)")
        }
        
        let sinceDate = since ?? Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        let sinceString = isoFormatter.string(from: sinceDate)
        filters.append("created_timestamp:>='\(sinceString)'")
        
        let filterString = filters.joined(separator: "+")
        
        print("Alerts API filter: \(filterString)")
        
        var allAlertIds: [String] = []
        var currentOffset: Int? = nil
        var totalCount = 0
        
        while true {
            try Task.checkCancellation()
            let (ids, nextOffset, total) = try await queryAlertIdsPage(filterString: filterString, limit: limit, offset: currentOffset)
            allAlertIds.append(contentsOf: ids)
            if let total { totalCount = total }
            currentOffset = nextOffset
            print("Fetched alert ID page: \(ids.count) ids (running total: \(allAlertIds.count), reported total: \(totalCount))")
            if nextOffset == nil || ids.isEmpty { break }
        }
        
        guard !allAlertIds.isEmpty else {
            print("No alert IDs returned")
            progressHandler(0, 0)
            return []
        }
        
        print("Fetched \(allAlertIds.count) total alert IDs from API")
        
        let filteredIds: [String]
        if filterThirdParty {
            let thirdPartyCount = allAlertIds.filter { Alert.isThirdPartyAlertId($0) }.count
            filteredIds = allAlertIds.filter { !Alert.isThirdPartyAlertId($0) }
            print("Filtering enabled: \(thirdPartyCount) third-party alerts removed, \(filteredIds.count) remaining")
        } else {
            filteredIds = allAlertIds
            print("Filtering disabled: keeping all \(filteredIds.count) alerts")
        }
        
        let totalCountToFetch = filteredIds.count
        progressHandler(0, totalCountToFetch)
        
        guard !filteredIds.isEmpty else {
            print("No non-third-party alerts to fetch")
            return []
        }
        
        var allAlerts: [Alert] = []
        let batchSize = 50
        var errorCount = 0
        var loggedFirstBatch = false
        let session = urlSession()
        
        for i in stride(from: 0, to: filteredIds.count, by: batchSize) {
            try Task.checkCancellation()
            
            let batchEnd = min(i + batchSize, filteredIds.count)
            let batchIds = Array(filteredIds[i..<batchEnd])
            
            print("Fetching alert batch \(i / batchSize + 1): IDs \(i) to \(batchEnd)")
            
            let detailsUrl = URL(string: "\(configuration.baseURLWithProtocol)/alerts/entities/alerts/v2")!
            
            var detailsRequest = URLRequest(url: detailsUrl)
            detailsRequest.httpMethod = "POST"
            detailsRequest.setValue(try authorizationHeader(), forHTTPHeaderField: "Authorization")
            detailsRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = ["composite_ids": batchIds]
            detailsRequest.httpBody = try? JSONSerialization.data(withJSONObject: body)
            detailsRequest.timeoutInterval = configuration.requestTimeout
            
            do {
                let (detailsData, detailsResponse) = try await session.data(for: detailsRequest)
                let statusCode = (detailsResponse as? HTTPURLResponse)?.statusCode ?? 0
                
                if !loggedFirstBatch {
                    logResponse(detailsData, label: "Alert Details Response (First Batch)")
                    loggedFirstBatch = true
                }
                
                if statusCode == 200 {
                    let decoder = JSONDecoder()
                    do {
                        let alertDetailsResponse = try decoder.decode(AlertDetailsResponse.self, from: detailsData)
                        logResponseErrors(alertDetailsResponse.errors, context: "Alert Details")
                        if let alerts = alertDetailsResponse.resources {
                            allAlerts.append(contentsOf: alerts)
                            print("Successfully decoded \(alerts.count) alerts in this batch")
                        } else {
                            print("No resources in alert details response")
                        }
                    } catch {
                        print("Failed to decode alert details: \(error)")
                        errorCount += 1
                    }
                    progressHandler(batchEnd, totalCountToFetch)
                } else {
                    print("Alert details fetch returned status code: \(statusCode)")
                    if let responseString = String(data: detailsData, encoding: .utf8) {
                        print("Error response: \(responseString)")
                    }
                    errorCount += 1
                }
            } catch is CancellationError {
                print("Alert fetch cancelled")
                throw CancellationError()
            } catch {
                print("Alert fetch error: \(error.localizedDescription)")
                errorCount += 1
            }
        }
        
        if let minSeverity {
            let beforeCount = allAlerts.count
            allAlerts = allAlerts.filter { ($0.severity ?? 0) >= minSeverity }
            let filteredCount = beforeCount - allAlerts.count
            if filteredCount > 0 {
                print("Client-side severity filter removed \(filteredCount) alerts below severity \(minSeverity)")
            }
        }
        
        print("Total alerts retrieved: \(allAlerts.count), errors encountered: \(errorCount)")
        return allAlerts
    }
    
    func testConnection() async throws -> Bool {
        try await ensureValidToken()
        
        var urlComponents = URLComponents(string: "\(configuration.baseURLWithProtocol)/devices/queries/devices/v1")!
        urlComponents.queryItems = [URLQueryItem(name: "limit", value: "1")]
        
        guard let url = urlComponents.url else { throw APIError.invalidResponse }
        
        var request = URLRequest(url: url)
        request.setValue(try authorizationHeader(), forHTTPHeaderField: "Authorization")
        request.timeoutInterval = configuration.connectionTimeout
        
        let session = urlSession()
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        return httpResponse.statusCode == 200
    }
}
