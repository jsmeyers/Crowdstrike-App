import SwiftUI

struct EndpointsListView: View {
    let hosts: [Host]
    @Binding var searchQuery: String
    
    var body: some View {
        List {
            ForEach(hosts) { host in
                NavigationLink(value: host) {
                    HostRow(host: host)
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchQuery, prompt: "Search endpoints...")
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
