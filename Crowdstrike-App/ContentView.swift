//
//  ContentView.swift
//  Crowdstrike-App
//
//  Created by scotteberg@gmail.com on 2/22/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HostsViewModel()
    
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
                        ContentUnavailableView {
                            Label("No Alerts", systemImage: "checkmark.shield")
                        } description: {
                            Text("No alerts to display")
                        }
                    } else {
                        AlertsView(alerts: viewModel.allAlerts)
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

// MARK: - Endpoints List View

struct EndpointsListView: View {
    let hosts: [Host]
    @Binding var searchQuery: String
    
    var body: some View {
        List {
            ForEach(hosts) { host in
                NavigationLink {
                    HostDetailView(host: host)
                } label: {
                    HostRowView(host: host)
                }
            }
        }
        .searchable(text: $searchQuery, prompt: "Search endpoints")
    }
}

// MARK: - Host Row View

struct HostRowView: View {
    let host: Host
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(host.displayName)
                .font(.headline)
            
            if let platform = host.platformName {
                Text(platform)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                if let status = host.status {
                    Label(status.capitalized, systemImage: statusIcon(for: status))
                        .font(.caption)
                        .foregroundStyle(statusColor(for: status))
                }
                
                if let lastSeen = host.lastSeenAgo {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(lastSeen)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private func statusIcon(for status: String) -> String {
        switch status.lowercased() {
        case "normal": return "checkmark.circle"
        case "containment": return "lock.shield"
        case "sensor_update": return "arrow.clockwise"
        default: return "questionmark.circle"
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "normal": return .green
        case "containment": return .red
        case "sensor_update": return .orange
        default: return .secondary
        }
    }
}

// MARK: - Copyable Field View

struct CopyableField: View {
    let label: String
    let value: String
    
    @State private var showCopiedConfirmation = false
    
    var body: some View {
        LabeledContent(label, value: value)
            .contentShape(Rectangle())
            .onTapGesture {
                copyToClipboard()
            }
            .contextMenu {
                Button {
                    copyToClipboard()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
            .overlay {
                if showCopiedConfirmation {
                    Text("Copied!")
                        .font(.caption)
                        .padding(6)
                        .background(.regularMaterial)
                        .clipShape(Capsule())
                        .transition(.opacity.combined(with: .scale))
                }
            }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = value
        
        withAnimation {
            showCopiedConfirmation = true
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                showCopiedConfirmation = false
            }
        }
    }
}

// MARK: - Host Detail View

struct HostDetailView: View {
    let host: Host
    
    var body: some View {
        List {
            Section("General") {
                if let hostname = host.hostname {
                    CopyableField(label: "Hostname", value: hostname)
                }
                CopyableField(label: "Device ID", value: host.id)
                if let platform = host.platformName {
                    CopyableField(label: "Platform", value: platform)
                }
                if let status = host.status {
                    CopyableField(label: "Status", value: status.capitalized)
                }
            }
            
            Section("Network") {
                if let localIp = host.localIp {
                    CopyableField(label: "Local IP", value: localIp)
                }
                if let externalIp = host.externalIp {
                    CopyableField(label: "External IP", value: externalIp)
                }
                if let macAddress = host.macAddress {
                    CopyableField(label: "MAC Address", value: macAddress)
                }
            }
            
            Section("Operating System") {
                if let osProduct = host.osProductName {
                    CopyableField(label: "OS", value: osProduct)
                }
                if let osVersion = host.osVersion {
                    CopyableField(label: "Version", value: osVersion)
                }
            }
            
            Section("Agent") {
                if let agentVersion = host.agentVersion {
                    CopyableField(label: "Agent Version", value: agentVersion)
                }
            }
            
            Section("Location") {
                if let city = host.city {
                    CopyableField(label: "City", value: city)
                }
                if let country = host.country {
                    CopyableField(label: "Country", value: country)
                }
                if let siteName = host.siteName {
                    CopyableField(label: "Site", value: siteName)
                }
            }
            
            Section("Timestamps") {
                if let lastSeen = host.lastSeen {
                    CopyableField(label: "Last Seen", value: formatDate(lastSeen))
                }
                if let firstSeen = host.firstSeen {
                    CopyableField(label: "First Seen", value: formatDate(firstSeen))
                }
                if let lastLoginUser = host.lastLoginUser {
                    CopyableField(label: "Last User", value: lastLoginUser)
                }
            }
            
            if let tags = host.tags, !tags.isEmpty {
                Section("Tags") {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .navigationTitle(host.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) else {
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: isoString) else {
                return isoString
            }
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

// MARK: - Alerts View

struct AlertsView: View {
    let alerts: [Alert]
    
    var body: some View {
        List {
            ForEach(alerts) { alert in
                NavigationLink {
                    AlertDetailView(alert: alert)
                } label: {
                    AlertRowView(alert: alert)
                }
            }
        }
    }
}

// MARK: - Alert Row View

struct AlertRowView: View {
    let alert: Alert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(alert.name ?? "Unknown Alert")
                .font(.headline)
            
            if let hostname = alert.hostname {
                Text(hostname)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Label(alert.severityText, systemImage: severityIcon(for: alert.severity))
                    .font(.caption)
                    .foregroundStyle(severityColor(for: alert.severity))
                
                if let createdAgo = alert.createdAgo {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(createdAgo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private func severityIcon(for severity: Int?) -> String {
        switch severity {
        case 4, 5: return "exclamationmark.octagon.fill"
        case 3: return "exclamationmark.triangle.fill"
        case 2: return "exclamationmark.circle.fill"
        case 1: return "info.circle.fill"
        default: return "circle"
        }
    }
    
    private func severityColor(for severity: Int?) -> Color {
        switch severity {
        case 4, 5: return .red
        case 3: return .orange
        case 2: return .yellow
        case 1: return .blue
        default: return .secondary
        }
    }
}

// MARK: - Alert Detail View

struct AlertDetailView: View {
    let alert: Alert
    
    var body: some View {
        List {
            Section("Alert Information") {
                if let name = alert.name {
                    CopyableField(label: "Name", value: name)
                }
                CopyableField(label: "ID", value: alert.id)
                CopyableField(label: "Severity", value: alert.severityText)
                CopyableField(label: "Status", value: alert.statusText)
            }
            
            if let description = alert.description {
                Section("Description") {
                    Text(description)
                        .textSelection(.enabled)
                }
            }
            
            Section("Details") {
                if let hostname = alert.hostname {
                    CopyableField(label: "Hostname", value: hostname)
                }
                if let username = alert.username {
                    CopyableField(label: "Username", value: username)
                }
                if let tactic = alert.tactic {
                    CopyableField(label: "Tactic", value: tactic)
                }
                if let technique = alert.technique {
                    CopyableField(label: "Technique", value: technique)
                }
                if let policyName = alert.policyName {
                    CopyableField(label: "Policy", value: policyName)
                }
            }
            
            Section("Timestamps") {
                if let createdTime = alert.createdTime {
                    CopyableField(label: "Created", value: formatDate(createdTime))
                }
                if let updatedTime = alert.updatedTime {
                    CopyableField(label: "Updated", value: formatDate(updatedTime))
                }
            }
        }
        .navigationTitle(alert.name ?? "Alert Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) else {
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: isoString) else {
                return isoString
            }
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Bindable var viewModel: HostsViewModel
    @State private var clientId = ""
    @State private var clientSecret = ""
    @State private var bearerToken = ""
    @State private var selectedRegion: CrowdStrikeRegion = .us1
    
    var body: some View {
        Form {
            Section {
                if viewModel.hasCredentials {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Authenticated")
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            await viewModel.logout()
                        }
                    } label: {
                        Text("Sign Out")
                    }
                } else {
                    Text("Not authenticated")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Authentication Status")
            }
            
            Section {
                Picker("Authentication Method", selection: $viewModel.configuration.authMethod) {
                    ForEach(AuthMethod.allCases) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
                
                Picker("Region", selection: $selectedRegion) {
                    ForEach(CrowdStrikeRegion.allCases) { region in
                        Text(region.displayName).tag(region)
                    }
                }
            } header: {
                Text("Configuration")
            }
            
            if viewModel.configuration.authMethod == .oauth {
                Section {
                    SecureField("Client ID", text: $clientId)
                        .textContentType(.username)
                    SecureField("Client Secret", text: $clientSecret)
                        .textContentType(.password)
                    
                    Button("Authenticate") {
                        Task {
                            await viewModel.authenticate(
                                clientId: clientId,
                                clientSecret: clientSecret,
                                region: selectedRegion
                            )
                        }
                    }
                    .disabled(clientId.isEmpty || clientSecret.isEmpty || viewModel.isLoading)
                } header: {
                    Text("OAuth2 Credentials")
                } footer: {
                    Text("Enter your CrowdStrike API credentials to authenticate.")
                }
            } else {
                Section {
                    SecureField("Bearer Token", text: $bearerToken)
                        .textContentType(.password)
                    
                    Button("Authenticate") {
                        Task {
                            await viewModel.authenticateWithBearerToken(bearerToken)
                        }
                    }
                    .disabled(bearerToken.isEmpty || viewModel.isLoading)
                } header: {
                    Text("Bearer Token")
                } footer: {
                    Text("Enter a pre-obtained bearer/access token.")
                }
            }
            
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                } header: {
                    Text("Error")
                }
            }
            
            Section {
                LabeledContent("Version", value: "1.0")
                LabeledContent("Region", value: selectedRegion.displayName)
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
        .task {
            selectedRegion = viewModel.configuration.region
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
