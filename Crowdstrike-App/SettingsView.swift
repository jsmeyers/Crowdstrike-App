import SwiftUI

struct SettingsView: View {
    @Bindable var viewModel: HostsViewModel
    
    @State private var clientId = ""
    @State private var clientSecret = ""
    @State private var bearerToken = ""
    @State private var customRegion = false
    @State private var isTestingConnection = false
    @State private var testConnectionResult: Bool? = nil
    
    var body: some View {
        Form {
            // MARK: - Account / Authentication
            if viewModel.hasCredentials {
                Section {
                    Button {
                        Task {
                            isTestingConnection = true
                            testConnectionResult = nil
                            let success = await viewModel.testConnection()
                            testConnectionResult = success
                            isTestingConnection = false
                        }
                    } label: {
                        HStack {
                            if isTestingConnection {
                                ProgressView()
                            } else {
                                Image(systemName: "wifi")
                            }
                            Text("Test Connection")
                            Spacer()
                            if let result = testConnectionResult {
                                Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(result ? .green : .red)
                            }
                        }
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            await viewModel.logout()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                        }
                    }
                } header: {
                    Text("Account")
                } footer: {
                    if viewModel.configuration.authMethod == .oauth {
                        Text("Authenticated via OAuth2")
                    } else {
                        Text("Authenticated via Bearer Token")
                    }
                }
            } else {
                Section {
                    Picker("Authentication Method", selection: $viewModel.configuration.authMethod) {
                        ForEach(AuthMethod.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    
                    Picker("Region", selection: $viewModel.configuration.region) {
                        ForEach(CrowdStrikeRegion.allCases) { region in
                            Text(region.displayName).tag(region)
                        }
                    }
                    
                    Toggle("Custom Base URL", isOn: $customRegion)
                    
                    if customRegion {
                        TextField("https://api.example.com", text: $viewModel.configuration.customBaseURL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                    }
                    
                    if viewModel.configuration.authMethod == .oauth {
                        TextField("Client ID", text: $clientId)
                            .autocapitalization(.none)
                        
                        SecureField("Client Secret", text: $clientSecret)
                            .autocapitalization(.none)
                        
                        Button("Authenticate") {
                            Task {
                                await viewModel.authenticate(
                                    clientId: clientId,
                                    clientSecret: clientSecret,
                                    region: viewModel.configuration.region
                                )
                            }
                        }
                    } else {
                        SecureField("Bearer Token", text: $bearerToken)
                            .autocapitalization(.none)
                        
                        Button("Authenticate") {
                            Task {
                                await viewModel.authenticateWithBearerToken(bearerToken)
                            }
                        }
                    }
                } header: {
                    Text("Authentication")
                }
            }
            
            // MARK: - Alerts
            Section {
                Picker("Minimum Severity", selection: $viewModel.configuration.alertMinSeverity) {
                    Text("Informational (0)").tag(0)
                    Text("Low (20)").tag(20)
                    Text("Medium (40)").tag(40)
                    Text("High (55)").tag(55)
                    Text("Critical (80)").tag(80)
                }
                
                Stepper("Lookback (Days): \(viewModel.configuration.alertLookbackDays)", value: $viewModel.configuration.alertLookbackDays, in: 1...30)
                
                Toggle("Filter Third-Party Alerts", isOn: $viewModel.configuration.filterThirdPartyAlerts)
            } header: {
                Text("Alerts")
            } footer: {
                Text("Adjusting these filters will apply on the next alert refresh.")
            }
            
            // MARK: - Endpoints
            Section {
                Toggle("Hide Stale Endpoints", isOn: $viewModel.configuration.hideStaleEndpoints)
                
                if viewModel.configuration.hideStaleEndpoints {
                    Stepper("Stale Threshold (Days): \(viewModel.configuration.staleEndpointDays)", value: $viewModel.configuration.staleEndpointDays, in: 1...90)
                }
            } header: {
                Text("Endpoints")
            }
            
            // MARK: - Network
            Section {
                Toggle("Enable Proxy", isOn: $viewModel.configuration.proxy.isEnabled)
                
                if viewModel.configuration.proxy.isEnabled {
                    TextField("Host", text: $viewModel.configuration.proxy.host)
                        .autocapitalization(.none)
                    
                    TextField("Port", value: $viewModel.configuration.proxy.port, format: .number)
                        .keyboardType(.numberPad)
                    
                    Toggle("Requires Auth", isOn: $viewModel.configuration.proxy.requiresAuth)
                }
            } header: {
                Text("Network")
            }
            
            // MARK: - Debug
            Section {
                Toggle("Enable Debug Logging", isOn: $viewModel.configuration.isDebugModeEnabled)
                
                if viewModel.configuration.isDebugModeEnabled {
                    Toggle("Verbose Logging", isOn: $viewModel.configuration.enableVerboseLogging)
                }
            } header: {
                Text("Debug")
            }
            
            // MARK: - About
            Section {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Region", value: viewModel.configuration.region.displayName)
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
        .onChange(of: viewModel.configuration) { _, _ in
            Task {
                await viewModel.saveConfiguration(viewModel.configuration)
            }
        }
    }
}
