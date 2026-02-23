//
//  HostsViewModel.swift
//  Crowdstrike-App
//
//  Created by scotteberg@gmail.com on 2/22/26.
//

import Foundation

@MainActor
@Observable
class HostsViewModel {
    
    // All hosts fetched from API (cache)
    private(set) var allHosts: [Host] = []
    
    // All alerts fetched from API
    private(set) var allAlerts: [Alert] = []
    
    // Search query - changing this automatically updates filteredHosts
    var searchQuery = "" {
        didSet {
            applyLocalFilter()
        }
    }
    
    // Filter state
    var selectedStatuses: Set<EndpointStatus> = [] {
        didSet {
            applyLocalFilter()
        }
    }
    
    var selectedPlatforms: Set<EndpointPlatform> = [] {
        didSet {
            applyLocalFilter()
        }
    }
    
    var isFilterActive: Bool {
        !selectedStatuses.isEmpty || !selectedPlatforms.isEmpty
    }
    
    // Filtered hosts for display
    private(set) var hosts: [Host] = []
    
    // Loading progress
    var isLoading = false
    var loadingMessage: String?
    var loadingProgress: Double = 0.0
    var loadedCount: Int = 0
    var totalCount: Int = 0
    
    // Refreshing state (for pull-to-refresh with cached data)
    var isRefreshing = false
    var refreshProgress: Double = 0.0
    var refreshLoadedCount: Int = 0
    var refreshTotalCount: Int = 0
    
    // Alert loading progress
    var isLoadingAlerts = false
    var alertLoadingProgress: Double = 0.0
    var alertLoadedCount: Int = 0
    var alertTotalCount: Int = 0
    
    // Tab selection
    var selectedTab: Tab = .endpoints
    
    var errorMessage: String?
    var hasCredentials = false
    var configuration: AppConfiguration = .load()
    var lastRefresh: Date?
    
    private let apiClient = CrowdStrikeAPIClient.shared
    
    // Cache URLs
    private let fileManager = FileManager.default
    private var cacheDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("CrowdStrikeCache", isDirectory: true)
    }
    private var hostsCacheURL: URL { cacheDirectory.appendingPathComponent("hosts.json") }
    private var alertsCacheURL: URL { cacheDirectory.appendingPathComponent("alerts.json") }
    private var lastRefreshURL: URL { cacheDirectory.appendingPathComponent("lastRefresh.json") }
    
    enum Tab: String, CaseIterable {
        case endpoints = "Endpoints"
        case alerts = "Alerts"
    }
    
    init() {
        // Load cached data immediately
        loadCachedData()
        
        Task {
            await checkCredentials()
            await loadConfiguration()
        }
    }
    
    // MARK: - Caching
    
    private func loadCachedData() {
        // Create cache directory if needed
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        
        // Load cached hosts
        if let data = try? Data(contentsOf: hostsCacheURL),
           let cachedHosts = try? JSONDecoder().decode([Host].self, from: data) {
            allHosts = cachedHosts
            applyLocalFilter()
            print("Loaded \(cachedHosts.count) cached hosts")
        }
        
        // Load cached alerts
        if let data = try? Data(contentsOf: alertsCacheURL),
           let cachedAlerts = try? JSONDecoder().decode([Alert].self, from: data) {
            allAlerts = cachedAlerts
            print("Loaded \(cachedAlerts.count) cached alerts")
        }
        
        // Load last refresh timestamp
        if let data = try? Data(contentsOf: lastRefreshURL),
           let refreshDate = try? JSONDecoder().decode(Date.self, from: data) {
            lastRefresh = refreshDate
        }
    }
    
    private func saveCachedData() {
        // Ensure cache directory exists
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
        
        // Save hosts
        if let data = try? JSONEncoder().encode(allHosts) {
            try? data.write(to: hostsCacheURL)
        }
        
        // Save alerts
        if let data = try? JSONEncoder().encode(allAlerts) {
            try? data.write(to: alertsCacheURL)
        }
        
        // Save last refresh timestamp
        if let date = lastRefresh, let data = try? JSONEncoder().encode(date) {
            try? data.write(to: lastRefreshURL)
        }
    }
    
    func loadConfiguration() async {
        configuration = await apiClient.getConfiguration()
        applyDebugSettings()
    }
    
    func saveConfiguration(_ config: AppConfiguration) async {
        config.save()
        configuration = config
        await apiClient.updateConfiguration(config)
        applyDebugSettings()
        // Re-apply filter in case stale endpoint setting changed
        applyLocalFilter()
    }
    
    private func applyDebugSettings() {
        // Sync debug settings to the DebugLogger singleton
        DebugLogger.shared.isEnabled = configuration.isDebugModeEnabled
        DebugLogger.shared.verboseEnabled = configuration.enableVerboseLogging
        
        // Sync debug settings to the API client
        Task {
            await apiClient.setLoggingEnabled(configuration.isDebugModeEnabled)
        }
    }
    
    func checkCredentials() async {
        let hasOAuth = await KeychainManager.shared.hasCredentials()
        let hasBearer = await KeychainManager.shared.hasBearerToken()
        hasCredentials = hasOAuth || hasBearer
        
        configuration = AppConfiguration.load()
        await apiClient.updateConfiguration(configuration)
        applyDebugSettings()
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
    
    /// Fetches ALL hosts from the API with pagination (full load screen)
    func refreshHosts() async {
        isLoading = true
        loadingMessage = "Fetching endpoints..."
        loadingProgress = 0
        loadedCount = 0
        totalCount = 0
        errorMessage = nil
        
        do {
            allHosts = try await apiClient.searchAndRetrieveHostsWithProgress(query: nil) { [weak self] loaded, total in
                Task { @MainActor in
                    self?.loadedCount = loaded
                    self?.totalCount = total
                    self?.loadingProgress = total > 0 ? Double(loaded) / Double(total) : 0
                    self?.loadingMessage = "Loading \(loaded) of \(total) endpoints..."
                }
            }
            lastRefresh = Date()
            applyLocalFilter()
            saveCachedData()
            
            // Also fetch alerts
            await refreshAlerts()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
        loadingMessage = nil
        loadingProgress = 0
    }
    
    /// Pull-to-refresh for endpoints (shows progress in subtitle)
    func refreshEndpoints() async {
        isRefreshing = true
        refreshProgress = 0
        refreshLoadedCount = 0
        refreshTotalCount = 0
        errorMessage = nil
        
        do {
            allHosts = try await apiClient.searchAndRetrieveHostsWithProgress(query: nil) { [weak self] loaded, total in
                Task { @MainActor in
                    self?.refreshLoadedCount = loaded
                    self?.refreshTotalCount = total
                    self?.refreshProgress = total > 0 ? Double(loaded) / Double(total) : 0
                }
            }
            lastRefresh = Date()
            applyLocalFilter()
            saveCachedData()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isRefreshing = false
        refreshProgress = 0
    }
    
    /// Fetches alerts from the API with progress
    func refreshAlerts() async {
        isLoadingAlerts = true
        alertLoadingProgress = 0
        alertLoadedCount = 0
        alertTotalCount = 0
        
        do {
            allAlerts = try await apiClient.fetchAlerts(
                limit: 500,
                filterThirdParty: configuration.filterThirdPartyAlerts
            ) { [weak self] loaded, total in
                Task { @MainActor in
                    self?.alertLoadedCount = loaded
                    self?.alertTotalCount = total
                    self?.alertLoadingProgress = total > 0 ? Double(loaded) / Double(total) : 0
                }
            }
            saveCachedData()
        } catch URLError.cancelled {
            print("Alert fetch cancelled - likely user navigated away")
        } catch {
            print("Failed to fetch alerts: \(error)")
        }
        
        isLoadingAlerts = false
        alertLoadingProgress = 0
    }
    
    /// Pull-to-refresh for alerts only
    func refreshAlertsOnly() async {
        isLoadingAlerts = true
        alertLoadingProgress = 0
        alertLoadedCount = 0
        alertTotalCount = 0
        errorMessage = nil
        
        await refreshAlerts()
    }
    
    /// Load hosts - uses cached data if available, otherwise fetches
    func loadHosts() async {
        if allHosts.isEmpty {
            await refreshHosts()
        } else {
            applyLocalFilter()
        }
    }
    
    /// Called by user action - kept for compatibility
    func searchHosts() async {
        applyLocalFilter()
    }
    
    /// Clear all filters
    func clearFilters() {
        selectedStatuses = []
        selectedPlatforms = []
        searchQuery = ""
    }
    
    /// Apply local search filter to cached hosts
    private func applyLocalFilter() {
        var filtered = allHosts
        
        // Filter out stale endpoints if enabled
        if configuration.hideStaleEndpoints {
            let cutoffDate = Date().addingTimeInterval(-Double(configuration.staleEndpointDays) * 24 * 60 * 60)
            filtered = filtered.filter { host in
                guard let lastSeen = host.lastSeenDate else { return false }
                return lastSeen >= cutoffDate
            }
        }
        
        // Apply status filter
        if !selectedStatuses.isEmpty {
            filtered = filtered.filter { host in
                guard let status = host.status?.lowercased() else { return false }
                return selectedStatuses.contains { filterStatus in
                    status == filterStatus.rawValue
                }
            }
        }
        
        // Apply platform filter
        if !selectedPlatforms.isEmpty {
            filtered = filtered.filter { host in
                guard let platform = host.platformName?.lowercased() else { return false }
                return selectedPlatforms.contains { filterPlatform in
                    platform.contains(filterPlatform.searchTerm)
                }
            }
        }
        
        // Apply search query filter
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard !trimmedQuery.isEmpty else {
            hosts = filtered
            return
        }
        
        hosts = filtered.filter { host in
            host.hostname?.lowercased().contains(trimmedQuery) == true ||
            host.localIp?.lowercased().contains(trimmedQuery) == true ||
            host.externalIp?.lowercased().contains(trimmedQuery) == true ||
            host.platformName?.lowercased().contains(trimmedQuery) == true ||
            host.osProductName?.lowercased().contains(trimmedQuery) == true ||
            host.osVersion?.lowercased().contains(trimmedQuery) == true ||
            host.machineDomain?.lowercased().contains(trimmedQuery) == true ||
            host.siteName?.lowercased().contains(trimmedQuery) == true ||
            host.lastLoginUser?.lowercased().contains(trimmedQuery) == true ||
            host.systemManufacturer?.lowercased().contains(trimmedQuery) == true ||
            host.systemProductName?.lowercased().contains(trimmedQuery) == true ||
            host.serialNumber?.lowercased().contains(trimmedQuery) == true ||
            host.status?.lowercased().contains(trimmedQuery) == true ||
            host.displayName.lowercased().contains(trimmedQuery) ||
            host.agentVersion?.lowercased().contains(trimmedQuery) == true ||
            host.tags?.contains { $0.lowercased().contains(trimmedQuery) } == true ||
            host.groupIds?.contains { $0.lowercased().contains(trimmedQuery) } == true
        }
    }
    
    /// Clear cache and logout
    func logout() async {
        do {
            try await KeychainManager.shared.clearAll()
            hasCredentials = false
            allHosts = []
            hosts = []
            allAlerts = []
            searchQuery = ""
            selectedStatuses = []
            selectedPlatforms = []
            errorMessage = nil
            lastRefresh = nil
            
            // Clear cached files
            try? fileManager.removeItem(at: hostsCacheURL)
            try? fileManager.removeItem(at: alertsCacheURL)
            try? fileManager.removeItem(at: lastRefreshURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func testConnection() async -> Bool {
        do {
            return try await apiClient.testConnection()
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

