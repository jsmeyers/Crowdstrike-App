//
//  AppConfiguration.swift
//  Crowdstrike-App
//
//  Created by scotteberg@gmail.com on 2/22/26.
//

import Foundation

// MARK: - Authentication Method

nonisolated enum AuthMethod: String, CaseIterable, Identifiable, Codable, Sendable {
    case oauth = "OAuth2"
    case bearerToken = "Bearer Token"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .oauth:
            return "Uses Client ID and Client Secret to obtain an access token"
        case .bearerToken:
            return "Directly use a pre-obtained bearer/access token"
        }
    }
}

// MARK: - Proxy Configuration

nonisolated struct ProxyConfiguration: Codable, Equatable, Sendable {
    var isEnabled: Bool = false
    var host: String = ""
    var port: Int = 8080
    var requiresAuth: Bool = false
    
    static let `default` = ProxyConfiguration()
    
    var isValid: Bool {
        guard isEnabled else { return true }
        return !host.isEmpty && port > 0 && port <= 65535
    }
}

// MARK: - App Configuration

nonisolated struct AppConfiguration: Codable, Equatable, Sendable {
    // Authentication
    var authMethod: AuthMethod = .oauth
    var region: CrowdStrikeRegion = .us1
    var customBaseURL: String = ""
    
    // Network
    var requestTimeout: Double = 30.0
    var connectionTimeout: Double = 10.0
    
    // Proxy
    var proxy: ProxyConfiguration = .default
    
    // Alerts
    var filterThirdPartyAlerts: Bool = true
    var alertMinSeverity: Int = 55
    var alertLookbackDays: Int = 7
    
    // Endpoints
    var hideStaleEndpoints: Bool = false
    var staleEndpointDays: Int = 30
    
    // Debug
    var isDebugModeEnabled: Bool = false
    var enableVerboseLogging: Bool = false
    
    // Computed Properties
    var effectiveBaseURL: String {
        if !customBaseURL.isEmpty {
            var url = customBaseURL.trimmingCharacters(in: .whitespaces)
            if url.hasSuffix("/") {
                url = String(url.dropLast())
            }
            if !url.hasPrefix("https://") && !url.hasPrefix("http://") {
                url = "https://\(url)"
            }
            return url.replacingOccurrences(of: "https://", with: "")
                        .replacingOccurrences(of: "http://", with: "")
        }
        return region.rawValue
    }
    
    var baseURLWithProtocol: String {
        return "https://\(effectiveBaseURL)"
    }
    
    static let `default` = AppConfiguration()
    
    // MARK: - Persistence
    
    private static let userDefaultsKey = "com.crowdstrike-app.configuration"
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
    
    static func load() -> AppConfiguration {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let config = try? JSONDecoder().decode(AppConfiguration.self, from: data) else {
            return .default
        }
        return config
    }
    
    static func reset() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

// MARK: - Debug Logger

actor DebugLogger {
    static let shared = DebugLogger()
    
    private var isEnabled: Bool = false
    private var verboseEnabled: Bool = false
    
    private init() {}
    
    func configure(isEnabled: Bool, verboseEnabled: Bool) {
        self.isEnabled = isEnabled
        self.verboseEnabled = verboseEnabled
    }
    
    func log(_ message: String, category: String = "General", isVerbose: Bool = false) {
        guard isEnabled else { return }
        if isVerbose && !verboseEnabled { return }
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let prefix = isVerbose ? "[VERBOSE]" : "[DEBUG]"
        print("\(timestamp) \(prefix) [\(category)] \(message)")
    }
    
    func logRequest(_ request: URLRequest) {
        guard isEnabled else { return }
        log("Request: \(request.httpMethod ?? "?") \(request.url?.absoluteString ?? "?")", category: "Network")
        if verboseEnabled, let headers = request.allHTTPHeaderFields {
            var safeHeaders = headers
            if safeHeaders["Authorization"] != nil {
                safeHeaders["Authorization"] = "***REDACTED***"
            }
            log("Headers: \(safeHeaders)", category: "Network", isVerbose: true)
        }
        if verboseEnabled, let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            let redacted = redactSensitive(bodyString)
            log("Body: \(redacted)", category: "Network", isVerbose: true)
        }
    }
    
    func logResponse(_ response: HTTPURLResponse?, data: Data?) {
        guard isEnabled else { return }
        log("Response: \(response?.statusCode ?? 0) \(response?.url?.absoluteString ?? "?")", category: "Network")
        if verboseEnabled, let data = data, let responseString = String(data: data, encoding: .utf8) {
            let truncated = String(responseString.prefix(500))
            log("Data: \(truncated)...", category: "Network", isVerbose: true)
        }
    }
    
    func logError(_ error: Error, context: String = "") {
        guard isEnabled else { return }
        log("Error: \(context) - \(error.localizedDescription)", category: "Error")
    }
    
    private nonisolated func redactSensitive(_ string: String) -> String {
        var result = string
        result = result.replacingOccurrences(
            of: "client_secret=[^&]+",
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
}
