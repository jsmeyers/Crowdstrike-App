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
            
            Section("Alerts") {
                Toggle("Filter Third-Party Alerts", isOn: $viewModel.configuration.filterThirdPartyAlerts)
                    .onChange(of: viewModel.configuration.filterThirdPartyAlerts) { _, newValue in
                        Task {
                            await viewModel.saveConfiguration(viewModel.configuration)
                        }
                    }
                
                Text("When enabled, alerts from third-party integrations are hidden from the alerts list.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
