import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: HostsViewModel
    @State private var clientId = ""
    @State private var clientSecret = ""
    @State private var bearerToken = ""
    @State private var selectedRegion: CrowdStrikeRegion = .us1
    @State private var showingSaveConfirmation = false
    @State private var showingLogoutConfirmation = false
    
    var body: some View {
        Form {
            Section("Authentication") {
                Picker("Auth Method", selection: $viewModel.configuration.authMethod) {
                    ForEach(AuthMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                .pickerStyle(.segmented)
                
                if viewModel.configuration.authMethod == .oauth {
                    TextField("Client ID", text: $clientId)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                    
                    SecureField("Client Secret", text: $clientSecret)
                        .textContentType(.password)
                    
                    Picker("Region", selection: $selectedRegion) {
                        ForEach(CrowdStrikeRegion.allCases) { region in
                            Text(region.displayName).tag(region)
                        }
                    }
                    
                    Button("Authenticate") {
                        Task {
                            await viewModel.authenticate(
                                clientId: clientId,
                                clientSecret: clientSecret,
                                region: selectedRegion
                            )
                        }
                    }
                    .disabled(clientId.isEmpty || clientSecret.isEmpty)
                } else {
                    SecureField("Bearer Token", text: $bearerToken)
                        .textContentType(.password)
                    
                    Button("Set Token") {
                        Task {
                            await viewModel.authenticateWithBearerToken(bearerToken)
                        }
                    }
                    .disabled(bearerToken.isEmpty)
                }
            }
            
            Section {
                if viewModel.hasCredentials {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Authenticated")
                    }
                } else {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                        Text("Not Authenticated")
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            
            Section("Endpoints") {
                Toggle("Hide Stale Endpoints", isOn: $viewModel.configuration.hideStaleEndpoints)
                    .onChange(of: viewModel.configuration.hideStaleEndpoints) { _, newValue in
                        Task {
                            await viewModel.saveConfiguration(viewModel.configuration)
                        }
                    }
                
                if viewModel.configuration.hideStaleEndpoints {
                    Stepper("Days: \(viewModel.configuration.staleEndpointDays)", value: $viewModel.configuration.staleEndpointDays, in: 7...90)
                        .onChange(of: viewModel.configuration.staleEndpointDays) { _, newValue in
                            Task {
                                await viewModel.saveConfiguration(viewModel.configuration)
                            }
                        }
                }
                
                Text("When enabled, endpoints that haven't connected in the specified number of days will be hidden from the list.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section("Alerts") {
                Toggle("Filter Third-Party Alerts", isOn: $viewModel.configuration.filterThirdPartyAlerts)
                    .onChange(of: viewModel.configuration.filterThirdPartyAlerts) { _, newValue in
                        Task {
                            await viewModel.saveConfiguration(viewModel.configuration)
                        }
                    }
                
                Text("When enabled, alerts from third-party integrations are hidden. Toggle this off to see all alerts including third-party ones.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button("Refresh Alerts") {
                    Task {
                        await viewModel.refreshAlerts()
                    }
                }
                .disabled(!viewModel.hasCredentials || viewModel.isLoadingAlerts)
            }
            
            Section {
                Button("Test Connection", role: .none) {
                    Task {
                        _ = await viewModel.testConnection()
                    }
                }
                .disabled(!viewModel.hasCredentials)
                
                Button("Logout", role: .destructive) {
                    showingLogoutConfirmation = true
                }
                .disabled(!viewModel.hasCredentials)
            }
            
            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Region", value: viewModel.configuration.region.displayName)
                if let lastRefresh = viewModel.lastRefresh {
                    LabeledContent("Last Refresh", value: lastRefresh, format: .dateTime)
                }
                LabeledContent("Total Endpoints", value: "\(viewModel.allHosts.count)")
                LabeledContent("Visible Endpoints", value: "\(viewModel.hosts.count)")
                LabeledContent("Total Alerts", value: "\(viewModel.allAlerts.count)")
            }
        }
        .navigationTitle("Settings")
        .alert("Logged Out", isPresented: $showingLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                Task {
                    await viewModel.logout()
                }
            }
        } message: {
            Text("Are you sure you want to log out? This will clear all cached data.")
        }
    }
}
