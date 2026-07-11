import SwiftUI

struct EndpointsListView: View {
    let hosts: [HostEntity]
    
    @Binding var searchQuery: String
    
    var totalCount: Int = 0
    var isFilterActive: Bool = false
    var lastRefresh: Date?
    var isRefreshing: Bool = false
    var refreshLoadedCount: Int = 0
    var refreshTotalCount: Int = 0
    var onRefresh: () async -> Void
    
    @State private var searchDebounceTask: Task<Void, Never>?
    var onSearchApply: ((String) -> Void)? = nil
    
    var body: some View {
        List {
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
        .searchable(text: $searchQuery, prompt: "Search endpoints...")
        .onChange(of: searchQuery) { _, newValue in
            searchDebounceTask?.cancel()
            
            searchDebounceTask = Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                if !Task.isCancelled {
                    onSearchApply?(newValue)
                }
            }
        }
        .onDisappear {
            searchDebounceTask?.cancel()
        }
        .navigationDestination(for: HostEntity.self) { host in
            HostDetailView(host: host)
        }
    }
}

struct HostRow: View {
    let host: HostEntity
    
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
