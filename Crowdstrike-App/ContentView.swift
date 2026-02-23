import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HostsViewModel()
    @State private var showFilters = false
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            // Endpoints Tab
            NavigationStack {
                Group {
                    if viewModel.isLoading && viewModel.allHosts.isEmpty {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text("Loading endpoints...")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            if viewModel.totalCount > 0 {
                                VStack(spacing: 8) {
                                    ProgressView(value: viewModel.loadingProgress)
                                        .progressViewStyle(.linear)
                                        .frame(width: 200)
                                    
                                    Text("\(viewModel.loadedCount) of \(viewModel.totalCount) endpoints")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                    } else if !viewModel.hasCredentials {
                        ContentUnavailableView {
                            Label("Not Authenticated", systemImage: "lock.shield")
                        } description: {
                            Text("Go to Settings to configure your credentials")
                        }
                    } else if viewModel.allHosts.isEmpty {
                        // Empty state wrapped in ScrollView for pull-to-refresh
                        ScrollView {
                            ContentUnavailableView {
                                Label("No Endpoints", systemImage: "desktopcomputer.trianglebadge.exclamationmark")
                            } description: {
                                Text("Pull down to refresh or check your credentials")
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .refreshable {
                            await viewModel.refreshEndpoints()
                        }
                    } else {
                        EndpointsListView(
                            hosts: viewModel.hosts,
                            onSearchQueryChange: { query in
                                viewModel.searchQuery = query
                            },
                            totalCount: viewModel.allHosts.count,
                            isFilterActive: viewModel.isFilterActive,
                            lastRefresh: viewModel.lastRefresh,
                            isRefreshing: viewModel.isRefreshing,
                            refreshLoadedCount: viewModel.refreshLoadedCount,
                            refreshTotalCount: viewModel.refreshTotalCount
                        ) {
                            await viewModel.refreshEndpoints()
                        }
                    }
                }
                .navigationTitle("Endpoints")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 12) {
                            if viewModel.isRefreshing {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            FilterButton(
                                isActive: viewModel.isFilterActive,
                                action: { showFilters = true }
                            )
                        }
                    }
                }
                .sheet(isPresented: $showFilters) {
                    EndpointsFilterView(
                        selectedStatuses: $viewModel.selectedStatuses,
                        selectedPlatforms: $viewModel.selectedPlatforms,
                        isPresented: $showFilters,
                        clearFilters: { viewModel.clearFilters() }
                    )
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
            }
            .tabItem {
                Label("Endpoints", systemImage: "desktopcomputer")
            }
            .tag(HostsViewModel.Tab.endpoints)
            
            // Alerts Tab
            NavigationStack {
                Group {
                    if viewModel.isLoadingAlerts && viewModel.allAlerts.isEmpty {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            
                            Text("Loading alerts...")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            if viewModel.alertTotalCount > 0 {
                                VStack(spacing: 8) {
                                    ProgressView(value: viewModel.alertLoadingProgress)
                                        .progressViewStyle(.linear)
                                        .frame(width: 200)
                                    
                                    Text("\(viewModel.alertLoadedCount) of \(viewModel.alertTotalCount) alerts")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding()
                    } else if !viewModel.hasCredentials {
                        ContentUnavailableView {
                            Label("Not Authenticated", systemImage: "lock.shield")
                        } description: {
                            Text("Go to Settings to configure your credentials")
                        }
                    } else if viewModel.allAlerts.isEmpty {
                        // Empty state wrapped in ScrollView for pull-to-refresh
                        ScrollView {
                            ContentUnavailableView {
                                Label("No Alerts", systemImage: "checkmark.shield")
                            } description: {
                                Text("Pull down to refresh")
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .refreshable {
                            await viewModel.refreshAlertsOnly()
                        }
                    } else {
                        AlertsView(
                            rawAlerts: viewModel.allAlerts,
                            lastRefresh: viewModel.lastRefresh,
                            isRefreshing: viewModel.isLoadingAlerts,
                            refreshLoadedCount: viewModel.alertLoadedCount,
                            refreshTotalCount: viewModel.alertTotalCount
                        ) {
                            await viewModel.refreshAlertsOnly()
                        }
                    }
                }
                .navigationTitle("Alerts")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        if viewModel.isLoadingAlerts && !viewModel.allAlerts.isEmpty {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
            }
            .tabItem {
                Label("Alerts", systemImage: "exclamationmark.shield")
            }
            .tag(HostsViewModel.Tab.alerts)
            
            // Settings Tab
            NavigationStack {
                SettingsView(viewModel: viewModel)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .task {
            if viewModel.hasCredentials && viewModel.allHosts.isEmpty {
                await viewModel.loadHosts()
            }
        }
    }
}

// MARK: - Filter Button

struct FilterButton: View {
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                if isActive {
                    Text("Filter")
                        .font(.caption)
                }
            }
            .foregroundStyle(isActive ? .blue : .secondary)
        }
    }
}

// MARK: - Endpoints Filter View

struct EndpointsFilterView: View {
    @Binding var selectedStatuses: Set<EndpointStatus>
    @Binding var selectedPlatforms: Set<EndpointPlatform>
    @Binding var isPresented: Bool
    let clearFilters: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(EndpointStatus.allCases) { status in
                        Button {
                            if selectedStatuses.contains(status) {
                                selectedStatuses.remove(status)
                            } else {
                                selectedStatuses.insert(status)
                            }
                        } label: {
                            HStack {
                                Label(status.displayName, systemImage: status.icon)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedStatuses.contains(status) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Status")
                } footer: {
                    Text("Show only endpoints with the selected statuses")
                }
                
                Section {
                    ForEach(EndpointPlatform.allCases) { platform in
                        Button {
                            if selectedPlatforms.contains(platform) {
                                selectedPlatforms.remove(platform)
                            } else {
                                selectedPlatforms.insert(platform)
                            }
                        } label: {
                            HStack {
                                Label(platform.displayName, systemImage: platform.icon)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedPlatforms.contains(platform) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Platform")
                } footer: {
                    Text("Show only endpoints running the selected platforms")
                }
            }
            .navigationTitle("Filter Endpoints")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") {
                        clearFilters()
                    }
                    .disabled(selectedStatuses.isEmpty && selectedPlatforms.isEmpty)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

