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
    
    // Filtered hosts for display
    private(set) var hosts: [Host] = []
    
    // Loading progress
    var isLoading = false
    var loadingMessage: String?
    var loadingProgress: Double = 0.0
    var loadedCount: Int = 0
    var totalCount: Int = 0
    
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
    
    enum Tab: String, CaseIterable {
        case endpoints = "Endpoints"
        case alerts = "Alerts"
    }
    
    init() {
        Task {
            await checkCredentials()
            await loadConfiguration()
        }
    }
    
    func loadConfiguration() async {
        configuration = await apiClient.getConfiguration()
    }
    
    func saveConfiguration(_ config: AppConfiguration) async {
        config.save()
        configuration = config
        await apiClient.updateConfiguration(config)
    }
    
    func checkCredentials() async {
        let hasOAuth = await KeychainManager.shared.hasCredentials()
        let hasBearer = await KeychainManager.shared.hasBearerToken()
        hasCredentials = hasOAuth || hasBearer
        
        configuration = AppConfiguration.load()
        await apiClient.updateConfiguration(configuration)
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
    
    /// Fetches ALL hosts from the API with pagination
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
            
            // Also fetch alerts
            await refreshAlerts()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
        loadingMessage = nil
        loadingProgress = 0
    }
    
    /// Fetches alerts from the API with progress
    func refreshAlerts() async {
        isLoadingAlerts = true
        alertLoadingProgress = 0
        alertLoadedCount = 0
        alertTotalCount = 0
        
        do {
            allAlerts = try await apiClient.fetchAlerts(limit: 500) { [weak self] loaded, total in
                Task { @MainActor in
                    self?.alertLoadedCount = loaded
                    self?.alertTotalCount = total
                    self?.alertLoadingProgress = total > 0 ? Double(loaded) / Double(total) : 0
                }
            }
        } catch URLError.cancelled {
            print("Alert fetch cancelled - likely user navigated away")
        } catch {
            print("Failed to fetch alerts: \(error)")
        }
        
        isLoadingAlerts = false
        alertLoadingProgress = 0
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
    
    /// Apply local search filter to cached hosts
    private func applyLocalFilter() {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard !trimmedQuery.isEmpty else {
            hosts = allHosts
            return
        }
        
        hosts = allHosts.filter { host in
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
            errorMessage = nil
            lastRefresh = nil
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
