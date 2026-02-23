import SwiftUI

struct AlertsView: View {
    let rawAlerts: [Alert]
    
    var body: some View {
        List {
            ForEach(rawAlerts) { alert in
                NavigationLink(value: alert) {
                    AlertRow(alert: alert)
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Alert.self) { alert in
            AlertDetailView(alert: alert)
        }
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
                        .lineLimit(2)
                    
                    if let hostname = alert.hostname {
                        Text(hostname)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                severityBadge
            }
            
            if let scenario = alert.scenario {
                Text(scenario)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            HStack(spacing: 8) {
                if let tactic = alert.tactic {
                    Label(tactic, systemImage: "target")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
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
struct AlertDetailView: View {
    let alert: Alert
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        severityBadge
                        Spacer()
                        statusBadge
                    }
                    
                    Text(alert.name ?? "Unknown Alert")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let scenario = alert.scenario {
                        Text(scenario)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Overview Section
                GroupBox("Overview") {
                    VStack(alignment: .leading, spacing: 8) {
                        if let description = alert.description {
                            Text(description)
                                .font(.body)
                        }
                        
                        LabeledContent("Detection Source", value: alert.detectionSourceText)
                        
                        if let objective = alert.objective {
                            LabeledContent("Objective", value: objective)
                        }
                        
                        if let confidence = alert.confidence {
                            LabeledContent("Confidence", value: "\(confidence)%")
                        }
                        
                        if let type = alert.type {
                            LabeledContent("Type", value: type)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                // MITRE ATT&CK Section
                if alert.tactic != nil || alert.technique != nil {
                    GroupBox("MITRE ATT&CK") {
                        VStack(alignment: .leading, spacing: 8) {
                            if let tactic = alert.tactic {
                                LabeledContent("Tactic", value: tactic)
                            }
                            if let tacticId = alert.tacticId {
                                LabeledContent("Tactic ID", value: tacticId)
                                    .font(.caption)
                            }
                            if let technique = alert.technique {
                                LabeledContent("Technique", value: technique)
                            }
                            if let techniqueId = alert.techniqueId {
                                LabeledContent("Technique ID", value: techniqueId)
                                    .font(.caption)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
                
                // Host Information
                if alert.hasHostInfo {
                    GroupBox("Host") {
                        VStack(alignment: .leading, spacing: 8) {
                            if let hostname = alert.hostname {
                                LabeledContent("Hostname", value: hostname)
                            }
                            if let deviceId = alert.deviceId {
                                LabeledContent("Device ID", value: deviceId)
                                    .font(.caption)
                            }
                            if let platform = alert.platform {
                                LabeledContent("Platform", value: platform)
                            }
                            if let osVersion = alert.osVersion {
                                LabeledContent("OS Version", value: osVersion)
                            }
                            if let username = alert.username {
                                LabeledContent("User", value: username)
                            }
                            if let location = alert.locationText {
                                LabeledContent("Location", value: location)
                            }
                            if let site = alert.site {
                                LabeledContent("Site", value: site)
                            }
                            if let domain = alert.machineDomain {
                                LabeledContent("Domain", value: domain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
                
                // Process Information
                if alert.hasProcessInfo {
                    GroupBox("Process") {
                        VStack(alignment: .leading, spacing: 8) {
                            if let fileName = alert.fileName {
                                LabeledContent("File Name", value: fileName)
                            }
                            if let filePath = alert.filePath {
                                LabeledContent("Path", value: filePath)
                                    .font(.caption)
                            }
                            if let sha256 = alert.sha256 {
                                LabeledContent("SHA256", value: String(sha256.prefix(16)) + "...")
                                    .font(.caption)
                                    .textSelection(.enabled)
                            }
                            if let commandLine = alert.commandLine {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Command Line")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(commandLine)
                                        .font(.system(.caption, design: .monospaced))
                                        .textSelection(.enabled)
                                }
                            }
                            if let processId = alert.processId {
                                LabeledContent("PID", value: processId)
                            }
                            if let parentFileName = alert.parentFileName {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Parent Process")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(parentFileName)
                                    if let parentCmd = alert.parentCommandLine {
                                        Text(parentCmd)
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
                
                // Network Information
                if alert.isNetworkAlert {
                    GroupBox("Network") {
                        VStack(alignment: .leading, spacing: 8) {
                            if let proto = alert.networkProtocol {
                                LabeledContent("Protocol", value: proto.uppercased())
                            }
                            if let direction = alert.networkDirection {
                                LabeledContent("Direction", value: direction.capitalized)
                            }
                            if let localIp = alert.localIp {
                                HStack {
                                    Text("Local")
                                    Spacer()
                                    Text(localIp)
                                    if let port = alert.localPort {
                                        Text(":\(port)")
                                    }
                                }
                            }
                            if let remoteIp = alert.remoteIp {
                                HStack {
                                    Text("Remote")
                                    Spacer()
                                    Text(remoteIp)
                                    if let port = alert.remotePort {
                                        Text(":\(port)")
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
                
                // Timestamps
                GroupBox("Timeline") {
                    VStack(alignment: .leading, spacing: 8) {
                        if let createdDate = alert.createdDate {
                            LabeledContent("Created", value: createdDate, format: .dateTime)
                        }
                        if let updatedDate = alert.updatedDate {
                            LabeledContent("Updated", value: updatedDate, format: .dateTime)
                        }
                        if let startDate = alert.startDate {
                            LabeledContent("Start", value: startDate, format: .dateTime)
                        }
                        if let endDate = alert.endDate {
                            LabeledContent("End", value: endDate, format: .dateTime)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                // Tags
                if let tags = alert.tags, !tags.isEmpty {
                    GroupBox("Tags") {
                        FlowLayout(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.quaternary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Policy Information
                if alert.policyName != nil || alert.policyId != nil {
                    GroupBox("Policy") {
                        VStack(alignment: .leading, spacing: 8) {
                            if let policyName = alert.policyName {
                                LabeledContent("Policy", value: policyName)
                            }
                            if let policyId = alert.policyId {
                                LabeledContent("Policy ID", value: policyId)
                                    .font(.caption)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Alert Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    var severityBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: alert.severityIcon)
            Text(alert.severityText)
        }
        .font(.caption)
        .fontWeight(.semibold)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(severityColor)
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }
    
    @ViewBuilder
    var statusBadge: some View {
        Text(alert.statusText)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.15))
            .foregroundStyle(statusColor)
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
    
    var statusColor: Color {
        switch alert.status?.lowercased() {
        case "new": return .red
        case "in_progress", "in progress": return .orange
        case "closed": return .green
        case "reopened": return .yellow
        default: return .gray
        }
    }
}

// MARK: - Flow Layout for Tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

