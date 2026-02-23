import SwiftUI

struct AlertsView: View {
    let rawAlerts: [Alert]
    
    var body: some View {
        List {
            ForEach(rawAlerts) { alert in
                AlertRow(alert: alert)
            }
        }
        .listStyle(.plain)
    }
}

struct AlertRow: View {
    let alert: Alert
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.name ?? "Unknown Alert")
                        .font(.headline)
                    
                    if let hostname = alert.hostname {
                        Text(hostname)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                severityBadge
            }
            
            if let description = alert.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                if let tactic = alert.tactic {
                    Label(tactic, systemImage: "target")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let createdAgo = alert.createdAgo {
                    Text(createdAgo)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    var severityBadge: some View {
        Text(alert.severityText)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(severityColor)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
    
    var severityColor: Color {
        switch alert.severity {
        case 4, 5: return .red
        case 3: return .orange
        case 2: return .yellow
        case 1: return .blue
        default: return .gray
        }
    }
}
