//
//  Persistence.swift
//  Crowdstrike-App
//
//  Created by scotteberg@gmail.com on 2/22/26.
//

import Foundation
import SwiftData

// MARK: - Host Entity (SwiftData)

@Model
final class HostEntity {
    @Attribute(.unique) var id: String
    var hostname: String?
    var localIp: String?
    var externalIp: String?
    var macAddress: String?
    var osVersion: String?
    var osProductName: String?
    var platformName: String?
    var status: String?
    var lastSeen: String?
    var firstSeen: String?
    var country: String?
    var city: String?
    var agentVersion: String?
    var ou: String?
    var ouList: [String]?
    var groupIds: [String]?
    var cid: String?
    var majorVersion: String?
    var minorVersion: String?
    var buildNumber: String?
    var machineDomain: String?
    var siteName: String?
    var lastLoginUser: String?
    var lastLoginTimestamp: String?
    var productType: String?
    var productTypeDesc: String?
    var systemManufacturer: String?
    var systemProductName: String?
    var serialNumber: String?
    var chassisType: String?
    var chassisTypeDesc: String?
    var connectionIp: String?
    var defaultGatewayIp: String?
    var tags: [String]?
    
    // Store parsed dates for efficient querying/sorting
    var lastSeenDate: Date?
    var firstSeenDate: Date?
    var lastLoginDate: Date?
    
    init(from host: Host) {
        self.id = host.id
        self.hostname = host.hostname
        self.localIp = host.localIp
        self.externalIp = host.externalIp
        self.macAddress = host.macAddress
        self.osVersion = host.osVersion
        self.osProductName = host.osProductName
        self.platformName = host.platformName
        self.status = host.status
        self.lastSeen = host.lastSeen
        self.firstSeen = host.firstSeen
        self.country = host.country
        self.city = host.city
        self.agentVersion = host.agentVersion
        self.ou = host.ou
        self.ouList = host.ouList
        self.groupIds = host.groupIds
        self.cid = host.cid
        self.majorVersion = host.majorVersion
        self.minorVersion = host.minorVersion
        self.buildNumber = host.buildNumber
        self.machineDomain = host.machineDomain
        self.siteName = host.siteName
        self.lastLoginUser = host.lastLoginUser
        self.lastLoginTimestamp = host.lastLoginTimestamp
        self.productType = host.productType
        self.productTypeDesc = host.productTypeDesc
        self.systemManufacturer = host.systemManufacturer
        self.systemProductName = host.systemProductName
        self.serialNumber = host.serialNumber
        self.chassisType = host.chassisType
        self.chassisTypeDesc = host.chassisTypeDesc
        self.connectionIp = host.connectionIp
        self.defaultGatewayIp = host.defaultGatewayIp
        self.tags = host.tags
        self.lastSeenDate = host.lastSeenDate
        self.firstSeenDate = host.firstSeenDate
        self.lastLoginDate = host.lastLoginDate
    }
    
    var displayName: String { hostname ?? "Unknown Host" }
    
    var lastSeenAgo: String? {
        guard let date = lastSeenDate else { return nil }
        return date.timeAgoString()
    }
    
    var firstSeenAgo: String? {
        guard let date = firstSeenDate else { return nil }
        return date.timeAgoString()
    }
    
    var lastLoginAgo: String? {
        guard let date = lastLoginDate else { return nil }
        return date.timeAgoString()
    }
    
    var searchableFields: [String] {
        var fields: [String] = []
        fields.append(displayName.lowercased())
        if let hostname { fields.append(hostname.lowercased()) }
        if let localIp { fields.append(localIp.lowercased()) }
        if let externalIp { fields.append(externalIp.lowercased()) }
        if let platformName { fields.append(platformName.lowercased()) }
        if let osProductName { fields.append(osProductName.lowercased()) }
        if let osVersion { fields.append(osVersion.lowercased()) }
        if let machineDomain { fields.append(machineDomain.lowercased()) }
        if let siteName { fields.append(siteName.lowercased()) }
        if let lastLoginUser { fields.append(lastLoginUser.lowercased()) }
        if let systemManufacturer { fields.append(systemManufacturer.lowercased()) }
        if let systemProductName { fields.append(systemProductName.lowercased()) }
        if let serialNumber { fields.append(serialNumber.lowercased()) }
        if let status { fields.append(status.lowercased()) }
        if let agentVersion { fields.append(agentVersion.lowercased()) }
        if let tags { fields.append(contentsOf: tags.map { $0.lowercased() }) }
        if let groupIds { fields.append(contentsOf: groupIds.map { $0.lowercased() }) }
        return fields
    }
}

// MARK: - Alert Entity (SwiftData)

@Model
final class AlertEntity {
    @Attribute(.unique) var id: String
    var name: String?
    var alertDescription: String?
    var severity: Int?
    var status: String?
    var createdTime: String?
    var updatedTime: String?
    var tactic: String?
    var technique: String?
    var tacticId: String?
    var techniqueId: String?
    var cid: String?
    var type: String?
    var scenario: String?
    var objective: String?
    var patternId: String?
    var confidence: Int?
    var severityName: String?
    var startTime: String?
    var endTime: String?
    
    var fileName: String?
    var filePath: String?
    var sha256: String?
    var md5: String?
    var commandLine: String?
    var processId: String?
    var localProcessId: String?
    var userId: String?
    var userName: String?
    
    var parentDetailsData: Data? // Store as JSON Data for simplicity
    var grandparentDetailsData: Data?
    
    var localIp: String?
    var localPort: Int?
    var remoteIp: String?
    var remotePort: Int?
    var networkProtocol: String?
    var networkDirection: String?
    
    var country: String?
    var city: String?
    var rootSite: String?
    var siteId: String?
    var rootMachineDomain: String?
    var rootOu: String?
    
    var tags: [String]?
    var hostGroups: [String]?
    var assignedTo: String?
    var assignedToName: String?
    var policyId: String?
    var policyName: String?
    
    var deviceId: String?
    var deviceHostname: String?
    var devicePlatformName: String?
    var deviceOsVersion: String?
    var deviceCity: String?
    var deviceCountry: String?
    var deviceSiteName: String?
    var deviceMachineDomain: String?
    
    var compositeId: String?
    var agentId: String?
    
    // Store parsed date for efficient sorting
    var createdDate: Date?
    
    init(from alert: Alert) {
        self.id = alert.id
        self.name = alert.name
        self.alertDescription = alert.description
        self.severity = alert.severity
        self.status = alert.status
        self.createdTime = alert.createdTime
        self.updatedTime = alert.updatedTime
        self.tactic = alert.tactic
        self.technique = alert.technique
        self.tacticId = alert.tacticId
        self.techniqueId = alert.techniqueId
        self.cid = alert.cid
        self.type = alert.type
        self.scenario = alert.scenario
        self.objective = alert.objective
        self.patternId = alert.patternId
        self.confidence = alert.confidence
        self.severityName = alert.severityName
        self.startTime = alert.startTime
        self.endTime = alert.endTime
        
        self.fileName = alert.fileName
        self.filePath = alert.filePath
        self.sha256 = alert.sha256
        self.md5 = alert.md5
        self.commandLine = alert.commandLine
        self.processId = alert.processId
        self.localProcessId = alert.localProcessId
        self.userId = alert.userId
        self.userName = alert.userName
        
        if let parent = alert.parentDetails {
            self.parentDetailsData = try? JSONEncoder().encode(parent)
        }
        if let grandparent = alert.grandparentDetails {
            self.grandparentDetailsData = try? JSONEncoder().encode(grandparent)
        }
        
        self.localIp = alert.localIp
        self.localPort = alert.localPort
        self.remoteIp = alert.remoteIp
        self.remotePort = alert.remotePort
        self.networkProtocol = alert.networkProtocol
        self.networkDirection = alert.networkDirection
        
        self.country = alert.country
        self.city = alert.city
        self.rootSite = alert.rootSite
        self.siteId = alert.siteId
        self.rootMachineDomain = alert.rootMachineDomain
        self.rootOu = alert.rootOu
        
        self.tags = alert.tags
        self.hostGroups = alert.hostGroups
        self.assignedTo = alert.assignedTo
        self.assignedToName = alert.assignedToName
        self.policyId = alert.policyId
        self.policyName = alert.policyName
        
        self.deviceId = alert.device?.deviceId
        self.deviceHostname = alert.device?.hostname
        self.devicePlatformName = alert.device?.platformName
        self.deviceOsVersion = alert.device?.osVersion
        self.deviceCity = alert.device?.city
        self.deviceCountry = alert.device?.country
        self.deviceSiteName = alert.device?.siteName
        self.deviceMachineDomain = alert.device?.machineDomain
        
        self.compositeId = alert.compositeId
        self.agentId = alert.agentId
        
        self.createdDate = alert.createdDate
    }
    
    var hostname: String? { deviceHostname }
    var platform: String? { devicePlatformName }
    var osVersion: String? { deviceOsVersion }
    
    var parentFileName: String? {
        guard let data = parentDetailsData else { return nil }
        return (try? JSONDecoder().decode(AlertProcessDetails.self, from: data))?.filename
    }
    
    var parentCommandLine: String? {
        guard let data = parentDetailsData else { return nil }
        return (try? JSONDecoder().decode(AlertProcessDetails.self, from: data))?.cmdline
    }
    
    var locationText: String? {
        if let deviceCity = deviceCity, !deviceCity.isEmpty, let deviceCountry = deviceCountry, !deviceCountry.isEmpty {
            return "\(deviceCity), \(deviceCountry)"
        }
        if let city = city, !city.isEmpty, let country = country, !country.isEmpty {
            return "\(city), \(country)"
        }
        return nil
    }
    
    var username: String? { userName }
    var site: String? { rootSite ?? deviceSiteName }
    var machineDomain: String? { rootMachineDomain ?? deviceMachineDomain }
    
    var createdAgo: String? {
        guard let date = createdDate else { return nil }
        return date.timeAgoString()
    }
    
    var severityText: String {
        if let name = severityName, !name.isEmpty { return name }
        let severityValue = severity ?? -1
        switch severityValue {
        case 80...100: return "Critical"
        case 60..<80: return "High"
        case 40..<60: return "Medium"
        case 20..<40: return "Low"
        case 0..<20: return "Informational"
        default: return "Unknown"
        }
    }
    
    var severityIcon: String {
        let severityValue = severity ?? -1
        switch severityValue {
        case 80...100: return "exclamationmark.octagon.fill"
        case 60..<80: return "exclamationmark.triangle.fill"
        case 40..<60: return "exclamationmark.circle.fill"
        case 20..<40: return "info.circle.fill"
        case 0..<20: return "info.circle"
        default: return "questionmark.circle"
        }
    }
    
    var statusText: String {
        switch status?.lowercased() {
        case "new": return "New"
        case "in_progress", "in progress": return "In Progress"
        case "closed": return "Closed"
        case "reopened": return "Reopened"
        default: return status?.capitalized ?? "Unknown"
        }
    }
    
    var detectionSourceText: String { "CrowdStrike Falcon" }
    var isNetworkAlert: Bool { localIp != nil || remoteIp != nil || localPort != nil || remotePort != nil }
    var hasProcessInfo: Bool { fileName != nil || commandLine != nil || processId != nil || parentDetailsData != nil }
    var hasHostInfo: Bool { deviceId != nil || hostname != nil || platform != nil || osVersion != nil }
}
