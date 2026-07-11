import Foundation
import SwiftData

@MainActor
@Observable
class HostsViewModel {
    private let modelContext: ModelContext
    private let endpointRepository: EndpointRepository
    private let alertRepository: AlertRepository
    
    private(set) var allHosts: [HostEntity] = []
    private(set) var allAlerts: [AlertEntity] = []
    
    private var hostSearchIndex: [String: [String]] = [:]
    
    var searchQuery = ""
    
    var selectedStatuses: Set<EndpointStatus> = [] {
        didSet { applyLocalFilter() }
    }
    
    var selectedPlatforms: Set<EndpointPlatform> = [] {
        didSet { applyLocalFilter() }
    }
    
    var isFilterActive: Bool {
        !selectedStatuses.isEmpty || !selectedPlatforms.isEmpty
    }
    
    private(set) var hosts: [HostEntity] = []
    
    var isLoading = false
    var loadingMessage: String?
    var loadingProgress: Double = 0.0
    var loadedCount: Int = 0
    var totalCount: Int = 0
    
    var isRefreshing = false
    var refreshProgress: Double = 0.0
    var refreshLoadedCount: Int = 0
    var refreshTotalCount: Int = 0
    
    var isLoadingAlerts = false
    var alertLoadingProgress: Double = 0.0
    var alertLoadedCount: Int = 0
    var alertTotalCount: Int = 0
    
    var selectedTab: Tab = .endpoints
    
    var errorMessage: String?
    var hasCredentials = false
    var configuration: AppConfiguration = .load()
    var lastRefresh: Date?
    
    private let apiClient = CrowdStrikeAPIClient.shared
    
    enum Tab: String, CaseIterable {
        case endpoints = "Endpoints"
        case alerts = "Alerts"
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.endpointRepository = EndpointRepository(modelContext: modelContext)
        self.alertRepository = AlertRepository(modelContext: modelContext)
        loadCachedData()
        
        Task {
            await checkCredentials()
            await loadConfiguration()
        }
    }
    
    // MARK: - SwiftData Loading (via Repositories)
    
    private func loadCachedData() {
        do {
            let cachedHosts = try endpointRepository.fetchAll()
            allHosts = cachedHosts
            hostSearchIndex.removeAll(keepingCapacity: true)
            for host in cachedHosts {
                hostSearchIndex[host.id] = host.searchableFields
            }
            applyLocalFilter()
            
            let cachedAlerts = try alertRepository.fetchAllSortedByCreatedDate()
            allAlerts = cachedAlerts
            
            if let refreshDate = UserDefaults.standard.object(forKey: "lastRefresh") as? Date {
                lastRefresh = refreshDate
            }
            
            print("Loaded \(cachedHosts.count) cached hosts and \(cachedAlerts.count) cached alerts from SwiftData")
        } catch {
            print("Failed to load cached data: \(error)")
        }
    }
    
    func loadConfiguration() async {
        configuration = await apiClient.getConfiguration()
        await applyDebugSettings()
    }
    
    func saveConfiguration(_ config: AppConfiguration) async {
        config.save()
        configuration = config
        await apiClient.updateConfiguration(config)
        await applyDebugSettings()
        applyLocalFilter()
    }
    
    private func applyDebugSettings() async {
        await DebugLogger.shared.configure(
            isEnabled: configuration.isDebugModeEnabled,
            verboseEnabled: configuration.enableVerboseLogging
        )
    }
    
    func checkCredentials() async {
        let hasOAuth = await KeychainManager.shared.hasCredentials()
        let hasBearer = await KeychainManager.shared.hasBearerToken()
        hasCredentials = hasOAuth || hasBearer
        
        configuration = AppConfiguration.load()
        await apiClient.updateConfiguration(configuration)
        await applyDebugSettings()
    }
    
    func authenticate(clientId: String, clientSecret: String, region: CrowdStrikeRegion) async {
        isLoading = true
        loadingMessage = "Authenticating..."
        loadingProgress = 0
        loadedCount = 0
        totalCount = 0
        errorMessage = nil
        
        var config = configuration
        config.region = region
        config.authMethod = .oauth
        await saveConfiguration(config)
        
        do {
            try await apiClient.authenticate(clientId: clientId, clientSecret: clientSecret)
            hasCredentials = true
            await refreshHosts()
        } catch {
            errorMessage = error.localizedDescription
            hasCredentials = false
        }
        
        isLoading = false
        loadingMessage = nil
    }
    
    func authenticateWithBearerToken(_ token: String) async {
        isLoading = true
        loadingMessage = "Authenticating..."
        loadingProgress = 0
        loadedCount = 0
        totalCount = 0
        errorMessage = nil
        
        var config = configuration
        config.authMethod = .bearerToken
        await saveConfiguration(config)
        
        do {
            try await apiClient.setBearerToken(token)
            hasCredentials = true
            await refreshHosts()
        } catch {
            errorMessage = error.localizedDescription
            hasCredentials = false
        }
        
        isLoading = false
        loadingMessage = nil
    }
    
    func refreshHosts() async {
        isLoading = true
        loadingMessage = "Fetching endpoints..."
        loadingProgress = 0
        loadedCount = 0
        totalCount = 0
        errorMessage = nil
        
        do {
            let hosts = try await apiClient.searchAndRetrieveHostsWithProgress(query: nil) { [weak self] loaded, total in
                Task { @MainActor in
                    self?.loadedCount = loaded
                    self?.totalCount = total
                    self?.loadingProgress = total > 0 ? Double(loaded) / Double(total) : 0
                    self?.loadingMessage = "Loading \(loaded) of \(total) endpoints..."
                }
            }
            
            // Batch save via repository
            try endpointRepository.replaceAll(with: hosts)
            allHosts = try endpointRepository.fetchAll()
            hostSearchIndex.removeAll(keepingCapacity: true)
            for host in allHosts {
                hostSearchIndex[host.id] = host.searchableFields
            }
            
            lastRefresh = Date()
            UserDefaults.standard.set(lastRefresh, forKey: "lastRefresh")
            applyLocalFilter()
            
            errorMessage = nil
            await refreshAlerts()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
        loadingMessage = nil
        loadingProgress = 0
    }
    
    func refreshEndpoints() async {
        isRefreshing = true
        refreshProgress = 0
        refreshLoadedCount = 0
        refreshTotalCount = 0
        errorMessage = nil
        
        do {
            let hosts = try await apiClient.searchAndRetrieveHostsWithProgress(query: nil) { [weak self] loaded, total in
                Task { @MainActor in
                    self?.refreshLoadedCount = loaded
                    self?.refreshTotalCount = total
                    self?.refreshProgress = total > 0 ? Double(loaded) / Double(total) : 0
                }
            }
            
            try endpointRepository.replaceAll(with: hosts)
            allHosts = try endpointRepository.fetchAll()
            hostSearchIndex.removeAll(keepingCapacity: true)
            for host in allHosts {
                hostSearchIndex[host.id] = host.searchableFields
            }
            
            lastRefresh = Date()
            UserDefaults.standard.set(lastRefresh, forKey: "lastRefresh")
            applyLocalFilter()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isRefreshing = false
        refreshProgress = 0
    }
    
    func refreshAlerts() async {
        guard !isLoadingAlerts else { return }
        
        isLoadingAlerts = true
        alertLoadingProgress = 0
        alertLoadedCount = 0
        alertTotalCount = 0
        
        do {
            let lookbackDate = Date().addingTimeInterval(-Double(configuration.alertLookbackDays) * 24 * 60 * 60)
            
            let alerts = try await apiClient.fetchAlerts(
                limit: 500,
                minSeverity: configuration.alertMinSeverity,
                since: lookbackDate,
                filterThirdParty: configuration.filterThirdPartyAlerts
            ) { [weak self] loaded, total in
                Task { @MainActor in
                    self?.alertLoadedCount = loaded
                    self?.alertTotalCount = total
                    self?.alertLoadingProgress = total > 0 ? Double(loaded) / Double(total) : 0
                }
            }
            
            try alertRepository.replaceAll(with: alerts)
            allAlerts = try alertRepository.fetchAllSortedByCreatedDate()
        } catch is CancellationError {
            print("Alert fetch cancelled")
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to fetch alerts: \(error)")
        }
        
        isLoadingAlerts = false
        alertLoadingProgress = 0
    }
    
    func refreshAlertsOnly() async {
        errorMessage = nil
        await refreshAlerts()
    }
    
    func loadHosts() async {
        if allHosts.isEmpty {
            await refreshHosts()
        } else {
            applyLocalFilter()
        }
    }
    
    func setSearchQuery(_ query: String) {
        searchQuery = query
        applyLocalFilter()
    }
    
    func clearFilters() {
        selectedStatuses = []
        selectedPlatforms = []
        searchQuery = ""
        applyLocalFilter()
    }
    
    private func applyLocalFilter() {
        var filtered = allHosts
        
        if configuration.hideStaleEndpoints {
            let cutoffDate = Date().addingTimeInterval(-Double(configuration.staleEndpointDays) * 24 * 60 * 60)
            filtered = filtered.filter { host in
                guard let lastSeen = host.lastSeenDate else { return false }
                return lastSeen >= cutoffDate
            }
        }
        
        if !selectedStatuses.isEmpty {
            filtered = filtered.filter { host in
                guard let status = host.status?.lowercased() else { return false }
                return selectedStatuses.contains { $0.rawValue == status }
            }
        }
        
        if !selectedPlatforms.isEmpty {
            filtered = filtered.filter { host in
                guard let platform = host.platformName?.lowercased() else { return false }
                return selectedPlatforms.contains { platform.contains($0.searchTerm) }
            }
        }
        
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard !trimmedQuery.isEmpty else {
            hosts = filtered
            return
        }
        
        hosts = filtered.filter { host in
            guard let fields = hostSearchIndex[host.id] else {
                return host.searchableFields.contains { $0.contains(trimmedQuery) }
            }
            return fields.contains { $0.contains(trimmedQuery) }
        }
    }
    
    func logout() async {
        do {
            try await KeychainManager.shared.clearAll()
            await apiClient.clearAuthState()
            hasCredentials = false
            
            try endpointRepository.deleteAll()
            try alertRepository.deleteAll()
            
            allHosts = []
            hosts = []
            allAlerts = []
            searchQuery = ""
            selectedStatuses = []
            selectedPlatforms = []
            errorMessage = nil
            lastRefresh = nil
            hostSearchIndex.removeAll()
            
            UserDefaults.standard.removeObject(forKey: "lastRefresh")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func testConnection() async -> Bool {
        do {
            _ = try await apiClient.testConnection()
            let (canReadHosts, canReadAlerts, scopeError) = await apiClient.checkTokenScopes()
            
            if !canReadHosts || !canReadAlerts {
                errorMessage = scopeError ?? "Your API token is missing required read permissions."
                return false
            }
            
            if let scopeError {
                // It connected and can read data, but has too many scopes.
                // We treat this as a warning, not a hard failure.
                errorMessage = scopeError
                return true
            }
            
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

// MARK: - Filter Options

enum EndpointStatus: String, CaseIterable, Identifiable {
    case normal = "normal"
    case offline = "offline"
    case containment = "containment"
    case sensorDisabled = "sensor_disabled"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .offline: return "Offline"
        case .containment: return "Containment"
        case .sensorDisabled: return "Sensor Disabled"
        }
    }
    
    var icon: String {
        switch self {
        case .normal: return "checkmark.circle.fill"
        case .offline: return "moon.zzz.fill"
        case .containment: return "exclamationmark.shield.fill"
        case .sensorDisabled: return "xmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .normal: return "green"
        case .offline: return "orange"
        case .containment: return "red"
        case .sensorDisabled: return "red"
        }
    }
}

enum EndpointPlatform: String, CaseIterable, Identifiable {
    case windows
    case mac
    case linux
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .windows: return "Windows"
        case .mac: return "macOS"
        case .linux: return "Linux"
        }
    }
    
    var searchTerm: String {
        switch self {
        case .windows: return "windows"
        case .mac: return "mac"
        case .linux: return "linux"
        }
    }
    
    var icon: String {
        switch self {
        case .windows: return "pc"
        case .mac: return "desktopcomputer"
        case .linux: return "server.rack"
        }
    }
}

