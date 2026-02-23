import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HostsViewModel()
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            // Endpoints Tab — unchanged
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
                        ContentUnavailableView {
                            Label("No Endpoints", systemImage: "desktopcomputer.trianglebadge.exclamationmark")
                        } description: {
                            Text("Pull to refresh or check your credentials")
                        }
                    } else {
                        EndpointsListView(hosts: viewModel.hosts, searchQuery: $viewModel.searchQuery)
                    }
                }
                .navigationTitle("Endpoints")
                .toolbar {
                    ToolbarItem {
                        Button {
                            Task {
                                await viewModel.refreshHosts()
                            }
                        } label: {
                            if viewModel.isLoading {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(!viewModel.hasCredentials || viewModel.isLoading)
                    }
                }
            }
            .tabItem {
                Label("Endpoints", systemImage: "desktopcomputer")
            }
            .tag(HostsViewModel.Tab.endpoints)
            
            // Alerts Tab — *with fixed AlertsView call*
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
                        ContentUnavailableView {
                            Label("No Alerts", systemImage: "checkmark.shield")
                        } description: {
                            Text("No alerts to display")
                        }
                    } else {
                        AlertsView(rawAlerts: viewModel.allAlerts)
                    }
                }
                .navigationTitle("Alerts")
                .toolbar {
                    ToolbarItem {
                        Button {
                            Task {
                                await viewModel.refreshAlerts()
                            }
                        } label: {
                            if viewModel.isLoadingAlerts {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(!viewModel.hasCredentials || viewModel.isLoading)
                    }
                }
            }
            .tabItem {
                Label("Alerts", systemImage: "exclamationmark.shield")
            }
            .tag(HostsViewModel.Tab.alerts)
            
            // Settings Tab — unchanged
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

