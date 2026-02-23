import SwiftUI

struct EndpointsListView: View {
    let hosts: [Host]
    var onSearchQueryChange: (String) -> Void
    var totalCount: Int = 0
    var isFilterActive: Bool = false
    var lastRefresh: Date?
    var isRefreshing: Bool = false
    var refreshLoadedCount: Int = 0
    var refreshTotalCount: Int = 0
    var onRefresh: () async -> Void
    
    @State private var searchText = ""
    @State private var searchDebounceTask: Task<Void, Never>?
    
    var body: some View {
        List {
            // Refresh status header
            if isRefreshing {
                Section {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Spacer()
                        if refreshTotalCount > 0 {
                            Text("Refreshing... \(refreshLoadedCount) of \(refreshTotalCount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Refreshing...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
            
            Section {
                ForEach(hosts) { host in
                    NavigationLink(value: host) {
                        HostRow(host: host)
                    }
                }
            } footer: {
                if totalCount > 0 {
                    HStack {
                        Spacer()
                        Text("\(hosts.count) of \(totalCount) endpoints")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let lastRefresh = lastRefresh {
                            Text("• Updated \(lastRefresh.timeAgoString())")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await onRefresh()
        }
        .searchable(text: $searchText, prompt: "Search endpoints...")
        .onChange(of: searchText) { _, newValue in
            // Cancel previous debounce task
            searchDebounceTask?.cancel()
            
            // Create new debounced task
            searchDebounceTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                if !Task.isCancelled {
                    onSearchQueryChange(newValue)
                }
            }
        }
        .onDisappear {
            searchDebounceTask?.cancel()
        }
        .navigationDestination(for: Host.self) { host in
            HostDetailView(host: host)
        }
    }
}

struct HostRow: View {
    let host: Host
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(host.displayName)
                        .font(.headline)
                    
                    if let platform = host.platformName {
                        Text(platform)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                statusBadge
            }
            
            HStack(spacing: 12) {
                if let localIp = host.localIp {
                    Label(localIp, systemImage: "network")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let lastSeen = host.lastSeenAgo {
                    Label(lastSeen, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            if let agentVersion = host.agentVersion {
                Text("Agent: \(agentVersion)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    var statusBadge: some View {
        Text(host.status?.capitalized ?? "Unknown")
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
    
    var statusColor: Color {
        switch host.status?.lowercased() {
        case "normal", "online": return .green
        case "offline", "containment": return .orange
        case "sensor_disabled": return .red
        default: return .gray
        }
    }
}
