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
    
    // All alerts fetched from API (sorted by created date descending)
    private(set) var allAlerts: [Alert] = []
    
    /// Precomputed lowercased search index keyed by host id. Rebuilt whenever
    /// `allHosts` changes (via `setAllHosts`). Filtering uses this instead of
    /// allocating ~15 `lowercased()` strings per host on every keystroke.
    private var hostSearchIndex: [String: [String]] = [:]
    
    // Search query - updated explicitly via `setSearchQuery(_:)` (typically
    // debounced by the view). Filtering is NOT triggered in a `didSet` so the
    // view can own debounce timing and avoid double-filtering.
    var searchQuery = ""
    
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
            setAllHosts(cachedHosts)
            applyLocalFilter()
            print("Loaded \(cachedHosts.count) cached hosts")
        }
        
        // Load cached alerts
        if let data = try? Data(contentsOf: alertsCacheURL),
           let cachedAlerts = try? JSONDecoder().decode([Alert].self, from: data) {
            allAlerts = sortedAlerts(cachedAlerts)
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
        await applyDebugSettings()
    }
    
    func saveConfiguration(_ config: AppConfiguration) async {
        config.save()
        configuration = config
        await apiClient.updateConfiguration(config)
        await applyDebugSettings()
        // Re-apply filter in case stale endpoint setting changed
        applyLocalFilter()
    }
    
    /// Syncs debug settings to the `DebugLogger` actor and the API client.
    /// Now `async` because `DebugLogger` is an actor (flags are isolated).
    private func applyDebugSettings() async {
        await DebugLogger.shared.configure(
            isEnabled: configuration.isDebugModeEnabled,
            verboseEnabled: configuration.enableVerboseLogging
        )
        
        // Sync debug settings to the API client
        await apiClient.setLoggingEnabled(configuration.isDebugModeEnabled)
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
    
    /// Fetches ALL hosts from the API with pagination (full load screen)
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
            setAllHosts(hosts)
            lastRefresh = Date()
            applyLocalFilter()
            saveCachedData()
            
            // If the host fetch succeeded, clear any stale error so success is
            // reflected in the UI; alert failures will set a fresh message below.
            errorMessage = nil
            
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
            let hosts = try await apiClient.searchAndRetrieveHostsWithProgress(query: nil) { [weak self] loaded, total in
                Task { @MainActor in
                    self?.refreshLoadedCount = loaded
                    self?.refreshTotalCount = total
                    self?.refreshProgress = total > 0 ? Double(loaded) / Double(total) : 0
                }
            }
            setAllHosts(hosts)
            lastRefresh = Date()
            applyLocalFilter()
            saveCachedData()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isRefreshing = false
        refreshProgress = 0
    }
    
    /// Fetches alerts from the API with progress.
    ///
    /// Guards against overlapping fetches: if an alert fetch is already in
    /// progress (e.g., the initial `refreshHosts()` chain is running and the
    /// user pulls to refresh on the Alerts tab), this call returns early
    /// instead of launching a concurrent fetch.
    func refreshAlerts() async {
        guard !isLoadingAlerts else { return }
        
        isLoadingAlerts = true
        alertLoadingProgress = 0
        alertLoadedCount = 0
        alertTotalCount = 0
        
        do {
            let alerts = try await apiClient.fetchAlerts(
                limit: 500,
                filterThirdParty: configuration.filterThirdPartyAlerts
            ) { [weak self] loaded, total in
                Task { @MainActor in
                    self?.alertLoadedCount = loaded
                    self?.alertTotalCount = total
                    self?.alertLoadingProgress = total > 0 ? Double(loaded) / Double(total) : 0
                }
            }
            allAlerts = sortedAlerts(alerts)
            saveCachedData()
        } catch is CancellationError {
            // `fetchAlerts` now propagates cancellation as `CancellationError`
            // (previously it wrapped it in `APIErrorType.networkError(URLError(.cancelled))`,
            // which made this catch arm unreachable).
            print("Alert fetch cancelled - likely user navigated away")
        } catch {
            // Surface alert fetch failures to the user (previously only logged).
            errorMessage = error.localizedDescription
            print("Failed to fetch alerts: \(error)")
        }
        
        isLoadingAlerts = false
        alertLoadingProgress = 0
    }
    
    /// Pull-to-refresh for alerts only
    func refreshAlertsOnly() async {
        // Reuses `refreshAlerts()`, which guards against overlapping fetches.
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
    
    /// Updates the search query and re-applies the local filter.
    /// The view is responsible for debouncing calls to this method.
    func setSearchQuery(_ query: String) {
        searchQuery = query
        applyLocalFilter()
    }
    
    /// Clear all filters
    func clearFilters() {
        selectedStatuses = []
        selectedPlatforms = []
        searchQuery = ""
        applyLocalFilter()
    }
    
    /// Sort alerts by created date descending (most recent first).
    /// Alerts without a parseable created date sink to the bottom.
    private func sortedAlerts(_ alerts: [Alert]) -> [Alert] {
        return alerts.sorted { lhs, rhs in
            let lhsDate = lhs.createdDate ?? .distantPast
            let rhsDate = rhs.createdDate ?? .distantPast
            return lhsDate > rhsDate
        }
    }
    
    /// Sets `allHosts` and rebuilds the precomputed search index. All
    /// assignments to `allHosts` should go through this so the index stays
    /// in sync with the data.
    private func setAllHosts(_ hosts: [Host]) {
        allHosts = hosts
        hostSearchIndex.removeAll(keepingCapacity: true)
        for host in hosts {
            hostSearchIndex[host.id] = host.searchableFields
        }
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
        
        // Apply search query filter using the precomputed index.
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard !trimmedQuery.isEmpty else {
            hosts = filtered
            return
        }
        
        hosts = filtered.filter { host in
            guard let fields = hostSearchIndex[host.id] else {
                // Fallback: build on the fly if missing from the index.
                return host.searchableFields.contains { $0.contains(trimmedQuery) }
            }
            return fields.contains { $0.contains(trimmedQuery) }
        }
    }
    
    /// Clear cache and logout
    func logout() async {
        do {
            try await KeychainManager.shared.clearAll()
            // Drop the in-memory access token immediately so subsequent
            // operations don't briefly reuse stale credentials.
            await apiClient.clearAuthState()
            hasCredentials = false
            setAllHosts([])
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

