import SwiftUI

struct HostDetailView: View {
    let host: Host
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        statusBadge
                        Spacer()
                        if let platform = host.platformName {
                            Text(platform)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.quaternary)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(host.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let osProduct = host.osProductName {
                        Text(osProduct)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Network Information
                GroupBox("Network") {
                    VStack(alignment: .leading, spacing: 8) {
                        if let localIp = host.localIp {
                            CopyableField(label: "Local IP", value: localIp)
                        }
                        if let externalIp = host.externalIp {
                            CopyableField(label: "External IP", value: externalIp)
                        }
                        if let connectionIp = host.connectionIp {
                            CopyableField(label: "Connection IP", value: connectionIp)
                        }
                        if let defaultGateway = host.defaultGatewayIp {
                            CopyableField(label: "Default Gateway", value: defaultGateway)
                        }
                        if let macAddress = host.macAddress {
                            CopyableField(label: "MAC Address", value: macAddress)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                // System Information
                GroupBox("System") {
                    VStack(alignment: .leading, spacing: 8) {
                        if let manufacturer = host.systemManufacturer {
                            LabeledContent("Manufacturer", value: manufacturer)
                        }
                        if let product = host.systemProductName {
                            LabeledContent("Model", value: product)
                        }
                        if let serial = host.serialNumber {
                            CopyableField(label: "Serial Number", value: serial)
                        }
                        if let chassisType = host.chassisTypeDesc {
                            LabeledContent("Chassis", value: chassisType)
                        }
                        if let productType = host.productTypeDesc {
                            LabeledContent("Type", value: productType)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                // OS Information
                GroupBox("Operating System") {
                    VStack(alignment: .leading, spacing: 8) {
                        if let osVersion = host.osVersion {
                            LabeledContent("Version", value: osVersion)
                        }
                        if let major = host.majorVersion, let minor = host.minorVersion, let build = host.buildNumber {
                            LabeledContent("Build", value: "\(major).\(minor).\(build)")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                // Agent Information
                GroupBox("Falcon Agent") {
                    VStack(alignment: .leading, spacing: 8) {
                        if let agentVersion = host.agentVersion {
                            LabeledContent("Version", value: agentVersion)
                        }
                        if let cid = host.cid {
                            CopyableField(label: "CID", value: cid)
                        }
                        if let firstSeen = host.firstSeenAgo {
                            LabeledContent("First Seen", value: firstSeen)
                        }
                        if let lastSeen = host.lastSeenAgo {
                            LabeledContent("Last Seen", value: lastSeen)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                // Location & Organization
                if host.city != nil || host.country != nil || host.siteName != nil || host.machineDomain != nil || host.ou != nil {
                    GroupBox("Location & Organization") {
                        VStack(alignment: .leading, spacing: 8) {
                            if let city = host.city, let country = host.country {
                                LabeledContent("Location", value: "\(city), \(country)")
                            } else if let city = host.city {
                                LabeledContent("City", value: city)
                            } else if let country = host.country {
                                LabeledContent("Country", value: country)
                            }
                            if let site = host.siteName {
                                LabeledContent("Site", value: site)
                            }
                            if let domain = host.machineDomain {
                                LabeledContent("Domain", value: domain)
                            }
                            if let ou = host.ou {
                                LabeledContent("OU", value: ou)
                                    .font(.caption)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
                
                // User Information
                if host.lastLoginUser != nil || host.lastLoginAgo != nil {
                    GroupBox("Last User") {
                        VStack(alignment: .leading, spacing: 8) {
                            if let user = host.lastLoginUser {
                                CopyableField(label: "Username", value: user)
                            }
                            if let lastLogin = host.lastLoginAgo {
                                LabeledContent("Login Time", value: lastLogin)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
                
                // Groups
                if let groups = host.groups, !groups.isEmpty {
                    GroupBox("Host Groups") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(groups, id: \.id) { group in
                                HStack {
                                    Image(systemName: "person.3.fill")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)
                                    Text(group.name ?? group.id ?? "Unknown Group")
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
                
                // Tags
                if let tags = host.tags, !tags.isEmpty {
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
                
                // Device ID
                GroupBox("Device ID") {
                    CopyableField(label: "", value: host.id, showLabel: false)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Endpoint Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    var statusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
            Text(host.status?.capitalized ?? "Unknown")
        }
        .font(.caption)
        .fontWeight(.semibold)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(statusColor)
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }
    
    var statusIcon: String {
        switch host.status?.lowercased() {
        case "normal", "online": return "checkmark.circle.fill"
        case "offline": return "moon.zzz.fill"
        case "containment": return "exclamationmark.shield.fill"
        case "sensor_disabled": return "xmark.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    var statusColor: Color {
        switch host.status?.lowercased() {
        case "normal", "online": return .green
        case "offline": return .orange
        case "containment": return .red
        case "sensor_disabled": return .red
        default: return .gray
        }
    }
}

// MARK: - Copyable Field Component

struct CopyableField: View {
    let label: String
    let value: String
    var showLabel: Bool = true
    
    @State private var showCopiedConfirmation = false
    
    var body: some View {
        HStack {
            if showLabel && !label.isEmpty {
                Text(label)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            HStack(spacing: 4) {
                Text(value)
                    .font(showLabel ? .body : .system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                UIPasteboard.general.string = value
                withAnimation(.easeInOut(duration: 0.2)) {
                    showCopiedConfirmation = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showCopiedConfirmation = false
                    }
                }
            }
            .overlay {
                if showCopiedConfirmation {
                    Text("Copied!")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .transition(.opacity.combined(with: .scale))
                }
            }
        }
    }
}
