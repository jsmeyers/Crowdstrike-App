//
//  CrowdStrikeAPI.swift
//  Crowdstrike-App
//
//  Created by scotteberg@gmail.com on 2/22/26.
//

import Foundation

// MARK: - API Configuration

enum CrowdStrikeRegion: String, CaseIterable, Identifiable, Codable {
    case us1 = "api.crowdstrike.com"
    case us2 = "api.us-2.crowdstrike.com"
    case eu1 = "api.eu-1.crowdstrike.com"
    case usgov = "api.laggar.gcw.crowdstrike.com"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .us1: return "US-1"
        case .us2: return "US-2"
        case .eu1: return "EU-1"
        case .usgov: return "US Gov"
        }
    }
}

// MARK: - OAuth Token Response

struct OAuthTokenResponse: Codable {
    let accessToken: String?
    let expiresIn: Int?
    let tokenType: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }
}

// MARK: - Host Models

struct Host: Identifiable, Codable, Hashable {
    let id: String
    let hostname: String?
    let localIp: String?
    let externalIp: String?
    let macAddress: String?
    let osVersion: String?
    let osProductName: String?
    let platformName: String?
    let status: String?
    let lastSeen: String?
    let firstSeen: String?
    let country: String?
    let city: String?
    let agentVersion: String?
    let ou: String?
    let ouList: [String]?
    let groups: [HostGroup]?
    let groupIds: [String]?
    let cid: String?
    let majorVersion: String?
    let minorVersion: String?
    let buildNumber: String?
    let machineDomain: String?
    let siteName: String?
    let lastLoginUser: String?
    let lastLoginTimestamp: String?
    let productType: String?
    let productTypeDesc: String?
    let systemManufacturer: String?
    let systemProductName: String?
    let serialNumber: String?
    let chassisType: String?
    let chassisTypeDesc: String?
    let connectionIp: String?
    let defaultGatewayIp: String?
    let tags: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id = "device_id"
        case hostname
        case localIp = "local_ip"
        case externalIp = "external_ip"
        case macAddress = "mac_address"
        case osVersion = "os_version"
        case osProductName = "os_product_name"
        case platformName = "platform_name"
        case status
        case lastSeen = "last_seen"
        case firstSeen = "first_seen"
        case country
        case city
        case agentVersion = "agent_version"
        case ou
        case groups
        case cid
        case majorVersion = "major_version"
        case minorVersion = "minor_version"
        case buildNumber = "build_number"
        case machineDomain = "machine_domain"
        case siteName = "site_name"
        case lastLoginUser = "last_login_user"
        case lastLoginTimestamp = "last_login_timestamp"
        case productType = "product_type"
        case productTypeDesc = "product_type_desc"
        case systemManufacturer = "system_manufacturer"
        case systemProductName = "system_product_name"
        case serialNumber = "serial_number"
        case chassisType = "chassis_type"
        case chassisTypeDesc = "chassis_type_desc"
        case connectionIp = "connection_ip"
        case defaultGatewayIp = "default_gateway_ip"
        case tags
    }
    
    init(
        id: String,
        hostname: String? = nil,
        localIp: String? = nil,
        externalIp: String? = nil,
        macAddress: String? = nil,
        osVersion: String? = nil,
        osProductName: String? = nil,
        platformName: String? = nil,
        status: String? = nil,
        lastSeen: String? = nil,
        firstSeen: String? = nil,
        country: String? = nil,
        city: String? = nil,
        agentVersion: String? = nil,
        ou: String? = nil,
        groups: [HostGroup]? = nil
    ) {
        self.id = id
        self.hostname = hostname
        self.localIp = localIp
        self.externalIp = externalIp
        self.macAddress = macAddress
        self.osVersion = osVersion
        self.osProductName = osProductName
        self.platformName = platformName
        self.status = status
        self.lastSeen = lastSeen
        self.firstSeen = firstSeen
        self.country = country
        self.city = city
        self.agentVersion = agentVersion
        self.ou = ou
        self.ouList = nil
        self.groups = groups
        self.groupIds = nil
        self.cid = nil
        self.majorVersion = nil
        self.minorVersion = nil
        self.buildNumber = nil
        self.machineDomain = nil
        self.siteName = nil
        self.lastLoginUser = nil
        self.lastLoginTimestamp = nil
        self.productType = nil
        self.productTypeDesc = nil
        self.systemManufacturer = nil
        self.systemProductName = nil
        self.serialNumber = nil
        self.chassisType = nil
        self.chassisTypeDesc = nil
        self.connectionIp = nil
        self.defaultGatewayIp = nil
        self.tags = nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let deviceId = try? container.decode(String.self, forKey: .id) {
            id = deviceId
        } else if let deviceIdInt = try? container.decode(Int.self, forKey: .id) {
            id = String(deviceIdInt)
        } else {
            id = "unknown"
        }
        
        hostname = try container.decodeIfPresent(String.self, forKey: .hostname)
        localIp = try container.decodeIfPresent(String.self, forKey: .localIp)
        externalIp = try container.decodeIfPresent(String.self, forKey: .externalIp)
        macAddress = try container.decodeIfPresent(String.self, forKey: .macAddress)
        osVersion = try container.decodeIfPresent(String.self, forKey: .osVersion)
        osProductName = try container.decodeIfPresent(String.self, forKey: .osProductName)
        platformName = try container.decodeIfPresent(String.self, forKey: .platformName)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        lastSeen = try container.decodeIfPresent(String.self, forKey: .lastSeen)
        firstSeen = try container.decodeIfPresent(String.self, forKey: .firstSeen)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        agentVersion = try container.decodeIfPresent(String.self, forKey: .agentVersion)
        
        if let ouString = try? container.decodeIfPresent(String.self, forKey: .ou) {
            ou = ouString.isEmpty ? nil : ouString
            ouList = ouString.isEmpty ? nil : [ouString]
        } else if let ouArray = try? container.decodeIfPresent([String].self, forKey: .ou) {
            ouList = ouArray.isEmpty ? nil : ouArray
            ou = ouArray.isEmpty ? nil : ouArray.joined(separator: ", ")
        } else {
            ou = nil
            ouList = nil
        }
        
        if let groupObjects = try? container.decodeIfPresent([HostGroup].self, forKey: .groups) {
            groups = groupObjects
            groupIds = nil
        } else if let groupArray = try? container.decodeIfPresent([String].self, forKey: .groups) {
            groupIds = groupArray
            groups = groupArray.map { HostGroup(id: $0, name: nil) }
        } else {
            groups = nil
            groupIds = nil
        }
        
        cid = try container.decodeIfPresent(String.self, forKey: .cid)
        majorVersion = try container.decodeIfPresent(String.self, forKey: .majorVersion)
        minorVersion = try container.decodeIfPresent(String.self, forKey: .minorVersion)
        buildNumber = try container.decodeIfPresent(String.self, forKey: .buildNumber)
        machineDomain = try container.decodeIfPresent(String.self, forKey: .machineDomain)
        siteName = try container.decodeIfPresent(String.self, forKey: .siteName)
        lastLoginUser = try container.decodeIfPresent(String.self, forKey: .lastLoginUser)
        lastLoginTimestamp = try container.decodeIfPresent(String.self, forKey: .lastLoginTimestamp)
        productType = try container.decodeIfPresent(String.self, forKey: .productType)
        productTypeDesc = try container.decodeIfPresent(String.self, forKey: .productTypeDesc)
        systemManufacturer = try container.decodeIfPresent(String.self, forKey: .systemManufacturer)
        systemProductName = try container.decodeIfPresent(String.self, forKey: .systemProductName)
        serialNumber = try container.decodeIfPresent(String.self, forKey: .serialNumber)
        chassisType = try container.decodeIfPresent(String.self, forKey: .chassisType)
        chassisTypeDesc = try container.decodeIfPresent(String.self, forKey: .chassisTypeDesc)
        connectionIp = try container.decodeIfPresent(String.self, forKey: .connectionIp)
        defaultGatewayIp = try container.decodeIfPresent(String.self, forKey: .defaultGatewayIp)
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(hostname, forKey: .hostname)
        try container.encodeIfPresent(localIp, forKey: .localIp)
        try container.encodeIfPresent(externalIp, forKey: .externalIp)
        try container.encodeIfPresent(macAddress, forKey: .macAddress)
        try container.encodeIfPresent(osVersion, forKey: .osVersion)
        try container.encodeIfPresent(osProductName, forKey: .osProductName)
        try container.encodeIfPresent(platformName, forKey: .platformName)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(lastSeen, forKey: .lastSeen)
        try container.encodeIfPresent(firstSeen, forKey: .firstSeen)
        try container.encodeIfPresent(country, forKey: .country)
        try container.encodeIfPresent(city, forKey: .city)
        try container.encodeIfPresent(agentVersion, forKey: .agentVersion)
        try container.encodeIfPresent(ouList, forKey: .ou)
        try container.encodeIfPresent(groupIds, forKey: .groups)
        try container.encodeIfPresent(cid, forKey: .cid)
        try container.encodeIfPresent(majorVersion, forKey: .majorVersion)
        try container.encodeIfPresent(minorVersion, forKey: .minorVersion)
        try container.encodeIfPresent(buildNumber, forKey: .buildNumber)
        try container.encodeIfPresent(machineDomain, forKey: .machineDomain)
        try container.encodeIfPresent(siteName, forKey: .siteName)
        try container.encodeIfPresent(lastLoginUser, forKey: .lastLoginUser)
        try container.encodeIfPresent(lastLoginTimestamp, forKey: .lastLoginTimestamp)
        try container.encodeIfPresent(productType, forKey: .productType)
        try container.encodeIfPresent(productTypeDesc, forKey: .productTypeDesc)
        try container.encodeIfPresent(systemManufacturer, forKey: .systemManufacturer)
        try container.encodeIfPresent(systemProductName, forKey: .systemProductName)
        try container.encodeIfPresent(serialNumber, forKey: .serialNumber)
        try container.encodeIfPresent(chassisType, forKey: .chassisType)
        try container.encodeIfPresent(chassisTypeDesc, forKey: .chassisTypeDesc)
        try container.encodeIfPresent(connectionIp, forKey: .connectionIp)
        try container.encodeIfPresent(defaultGatewayIp, forKey: .defaultGatewayIp)
        try container.encodeIfPresent(tags, forKey: .tags)
    }
    
    var displayName: String { hostname ?? "Unknown Host" }
    
    var lastSeenDate: Date? {
        guard let lastSeen = lastSeen else { return nil }
        return parseISO8601Date(lastSeen)
    }
    
    var firstSeenDate: Date? {
        guard let firstSeen = firstSeen else { return nil }
        return parseISO8601Date(firstSeen)
    }
    
    var lastLoginDate: Date? {
        guard let lastLoginTimestamp = lastLoginTimestamp else { return nil }
        return parseISO8601Date(lastLoginTimestamp)
    }
    
    private func parseISO8601Date(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
    
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
}

// MARK: - HostGroup

struct HostGroup: Codable, Hashable {
    let id: String?
    let name: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "group_id"
        case name
    }
    
    init(id: String? = nil, name: String? = nil) {
        self.id = id
        self.name = name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
    }
}

// MARK: - Alert Model

struct Alert: Identifiable, Codable, Hashable {
    let id: String
    let name: String?
    let description: String?
    let severity: Int?
    let status: String?
    let createdTime: String?
    let updatedTime: String?
    let hostname: String?
    let username: String?
    let tactic: String?
    let technique: String?
    let tacticId: String?
    let techniqueId: String?
    let cid: String?
    let deviceId: String?
    let productId: String?
    let type: String?
    let policyId: String?
    let policyName: String?
    
    // Additional details
    let scenario: String?
    let objective: String?
    let patternId: String?
    let platform: String?
    let osVersion: String?
    let agentVersion: String?
    let serviceProvider: String?
    let serviceProviderId: String?
    let confidence: Int?
    let severityName: String?
    let displayTimestamp: String?
    let startTime: String?
    let endTime: String?
    let detectedByFalconX: Bool?
    let detectedBySensor: Bool?
    let detectedByCloud: Bool?
    let isFalconGroup: Bool?
    let isEndpointGroup: Bool?
    
    // Process/Execution details
    let fileName: String?
    let filePath: String?
    let sha256: String?
    let md5: String?
    let commandLine: String?
    let processId: String?
    let parentProcessId: String?
    let parentFileName: String?
    let parentCommandLine: String?
    
    // Network details
    let localIp: String?
    let localPort: Int?
    let remoteIp: String?
    let remotePort: Int?
    let networkProtocol: String?
    let networkDirection: String?
    
    // Location/Org details
    let country: String?
    let city: String?
    let site: String?
    let siteId: String?
    let machineDomain: String?
    let ou: String?
    
    // Tags and grouping
    let tags: [String]?
    let hostGroups: [String]?
    let assignedTo: String?
    let assignedToName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case severity
        case status
        case createdTime = "created_time"
        case updatedTime = "updated_time"
        case hostname
        case username = "user_name"
        case tactic
        case technique
        case tacticId = "tactic_id"
        case techniqueId = "technique_id"
        case cid
        case deviceId = "device_id"
        case productId = "product_id"
        case type
        case policyId = "policy_id"
        case policyName = "policy_name"
        
        // Additional details
        case scenario
        case objective
        case patternId = "pattern_id"
        case platform
        case osVersion = "os_version"
        case agentVersion = "agent_version"
        case serviceProvider = "service_provider"
        case serviceProviderId = "service_provider_id"
        case confidence
        case severityName = "severity_name"
        case displayTimestamp = "display_timestamp"
        case startTime = "start_time"
        case endTime = "end_time"
        case detectedByFalconX = "detected_by_falconx"
        case detectedBySensor = "detected_by_sensor"
        case detectedByCloud = "detected_by_cloud"
        case isFalconGroup = "is_falcon_group"
        case isEndpointGroup = "is_endpoint_group"
        
        // Process/Execution details
        case fileName = "filename"
        case filePath = "filepath"
        case sha256
        case md5
        case commandLine = "cmdline"
        case processId = "process_id"
        case parentProcessId = "parent_process_id"
        case parentFileName = "parent_filename"
        case parentCommandLine = "parent_cmdline"
        
        // Network details
        case localIp = "local_ip"
        case localPort = "local_port"
        case remoteIp = "remote_ip"
        case remotePort = "remote_port"
        case networkProtocol = "protocol"
        case networkDirection = "network_direction"
        
        // Location/Org details
        case country
        case city
        case site
        case siteId = "site_id"
        case machineDomain = "machine_domain"
        case ou
        
        // Tags and grouping
        case tags
        case hostGroups = "host_groups"
        case assignedTo = "assigned_to"
        case assignedToName = "assigned_to_name"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle ID as either String or Int
        if let idString = try? container.decode(String.self, forKey: .id) {
            id = idString
        } else if let idInt = try? container.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else {
            id = "unknown"
        }
        
        // Basic fields
        name = try container.decodeIfPresent(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        severity = try container.decodeIfPresent(Int.self, forKey: .severity)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        createdTime = try container.decodeIfPresent(String.self, forKey: .createdTime)
        updatedTime = try container.decodeIfPresent(String.self, forKey: .updatedTime)
        hostname = try container.decodeIfPresent(String.self, forKey: .hostname)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        tactic = try container.decodeIfPresent(String.self, forKey: .tactic)
        technique = try container.decodeIfPresent(String.self, forKey: .technique)
        tacticId = try container.decodeIfPresent(String.self, forKey: .tacticId)
        techniqueId = try container.decodeIfPresent(String.self, forKey: .techniqueId)
        cid = try container.decodeIfPresent(String.self, forKey: .cid)
        deviceId = try container.decodeIfPresent(String.self, forKey: .deviceId)
        productId = try container.decodeIfPresent(String.self, forKey: .productId)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        policyId = try container.decodeIfPresent(String.self, forKey: .policyId)
        policyName = try container.decodeIfPresent(String.self, forKey: .policyName)
        
        // Additional details
        scenario = try container.decodeIfPresent(String.self, forKey: .scenario)
        objective = try container.decodeIfPresent(String.self, forKey: .objective)
        
        // Handle patternId as either String or Int
        if let patternIdString = try? container.decodeIfPresent(String.self, forKey: .patternId) {
            patternId = patternIdString
        } else if let patternIdInt = try? container.decodeIfPresent(Int.self, forKey: .patternId) {
            patternId = String(patternIdInt)
        } else {
            patternId = nil
        }
        
        platform = try container.decodeIfPresent(String.self, forKey: .platform)
        osVersion = try container.decodeIfPresent(String.self, forKey: .osVersion)
        agentVersion = try container.decodeIfPresent(String.self, forKey: .agentVersion)
        serviceProvider = try container.decodeIfPresent(String.self, forKey: .serviceProvider)
        serviceProviderId = try container.decodeIfPresent(String.self, forKey: .serviceProviderId)
        confidence = try container.decodeIfPresent(Int.self, forKey: .confidence)
        severityName = try container.decodeIfPresent(String.self, forKey: .severityName)
        displayTimestamp = try container.decodeIfPresent(String.self, forKey: .displayTimestamp)
        startTime = try container.decodeIfPresent(String.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(String.self, forKey: .endTime)
        detectedByFalconX = try container.decodeIfPresent(Bool.self, forKey: .detectedByFalconX)
        detectedBySensor = try container.decodeIfPresent(Bool.self, forKey: .detectedBySensor)
        detectedByCloud = try container.decodeIfPresent(Bool.self, forKey: .detectedByCloud)
        isFalconGroup = try container.decodeIfPresent(Bool.self, forKey: .isFalconGroup)
        isEndpointGroup = try container.decodeIfPresent(Bool.self, forKey: .isEndpointGroup)
        
        // Process/Execution details
        fileName = try container.decodeIfPresent(String.self, forKey: .fileName)
        filePath = try container.decodeIfPresent(String.self, forKey: .filePath)
        sha256 = try container.decodeIfPresent(String.self, forKey: .sha256)
        md5 = try container.decodeIfPresent(String.self, forKey: .md5)
        commandLine = try container.decodeIfPresent(String.self, forKey: .commandLine)
        processId = try container.decodeIfPresent(String.self, forKey: .processId)
        parentProcessId = try container.decodeIfPresent(String.self, forKey: .parentProcessId)
        parentFileName = try container.decodeIfPresent(String.self, forKey: .parentFileName)
        parentCommandLine = try container.decodeIfPresent(String.self, forKey: .parentCommandLine)
        
        // Network details
        localIp = try container.decodeIfPresent(String.self, forKey: .localIp)
        localPort = try container.decodeIfPresent(Int.self, forKey: .localPort)
        remoteIp = try container.decodeIfPresent(String.self, forKey: .remoteIp)
        remotePort = try container.decodeIfPresent(Int.self, forKey: .remotePort)
        networkProtocol = try container.decodeIfPresent(String.self, forKey: .networkProtocol)
        networkDirection = try container.decodeIfPresent(String.self, forKey: .networkDirection)
        
        // Location/Org details
        country = try container.decodeIfPresent(String.self, forKey: .country)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        site = try container.decodeIfPresent(String.self, forKey: .site)
        siteId = try container.decodeIfPresent(String.self, forKey: .siteId)
        machineDomain = try container.decodeIfPresent(String.self, forKey: .machineDomain)
        ou = try container.decodeIfPresent(String.self, forKey: .ou)
        
        // Tags and grouping
        tags = try container.decodeIfPresent([String].self, forKey: .tags)
        hostGroups = try container.decodeIfPresent([String].self, forKey: .hostGroups)
        assignedTo = try container.decodeIfPresent(String.self, forKey: .assignedTo)
        assignedToName = try container.decodeIfPresent(String.self, forKey: .assignedToName)
    }
    
    // Hashable conformance - just hash the ID since it's already Identifiable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Alert, rhs: Alert) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Computed Properties
    
    var createdDate: Date? {
        guard let createdTime = createdTime else { return nil }
        return parseISO8601Date(createdTime)
    }
    
    var updatedDate: Date? {
        guard let updatedTime = updatedTime else { return nil }
        return parseISO8601Date(updatedTime)
    }
    
    var startDate: Date? {
        guard let startTime = startTime else { return nil }
        return parseISO8601Date(startTime)
    }
    
    var endDate: Date? {
        guard let endTime = endTime else { return nil }
        return parseISO8601Date(endTime)
    }
    
    var displayDate: Date? {
        guard let displayTimestamp = displayTimestamp else { return nil }
        return parseISO8601Date(displayTimestamp)
    }
    
    private func parseISO8601Date(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
    
    var createdAgo: String? {
        guard let date = createdDate else { return nil }
        return date.timeAgoString()
    }
    
    var updatedAgo: String? {
        guard let date = updatedDate else { return nil }
        return date.timeAgoString()
    }
    
    var severityText: String {
        if let name = severityName, !name.isEmpty {
            return name
        }
        switch severity {
        case 4, 5: return "Critical"
        case 3: return "High"
        case 2: return "Medium"
        case 1: return "Low"
        case 0: return "Informational"
        default: return "Unknown"
        }
    }
    
    var severityIcon: String {
        switch severity {
        case 4, 5: return "exclamationmark.octagon.fill"
        case 3: return "exclamationmark.triangle.fill"
        case 2: return "exclamationmark.circle.fill"
        case 1: return "info.circle.fill"
        case 0: return "info.circle"
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
    
    var statusColor: String {
        switch status?.lowercased() {
        case "new": return "red"
        case "in_progress", "in progress": return "orange"
        case "closed": return "green"
        case "reopened": return "yellow"
        default: return "gray"
        }
    }
    
    var detectionSourceText: String {
        var sources: [String] = []
        if detectedBySensor == true { sources.append("Sensor") }
        if detectedByCloud == true { sources.append("Cloud") }
        if detectedByFalconX == true { sources.append("Falcon X") }
        return sources.isEmpty ? "Unknown" : sources.joined(separator: ", ")
    }
    
    var isNetworkAlert: Bool {
        localIp != nil || remoteIp != nil || localPort != nil || remotePort != nil
    }
    
    var hasProcessInfo: Bool {
        fileName != nil || commandLine != nil || processId != nil
    }
    
    var networkSummary: String? {
        guard isNetworkAlert else { return nil }
        var parts: [String] = []
        if let proto = networkProtocol {
            parts.append(proto.uppercased())
        }
        if let local = localIp, let port = localPort {
            parts.append("\(local):\(port)")
        } else if let local = localIp {
            parts.append(local)
        }
        if let direction = networkDirection {
            parts.append(direction)
        }
        if let remote = remoteIp, let port = remotePort {
            parts.append("→ \(remote):\(port)")
        } else if let remote = remoteIp {
            parts.append("→ \(remote)")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
    
    var processSummary: String? {
        guard hasProcessInfo else { return nil }
        var parts: [String] = []
        if let file = fileName {
            parts.append(file)
        }
        if let cmd = commandLine {
            let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count > 100 {
                parts.append(String(trimmed.prefix(100)) + "...")
            } else if !trimmed.isEmpty {
                parts.append(trimmed)
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }
    
    var locationText: String? {
        var parts: [String] = []
        if let city = city, !city.isEmpty { parts.append(city) }
        if let country = country, !country.isEmpty { parts.append(country) }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}

// MARK: - API Response Models

struct HostsResponse: Codable {
    let resources: [String]?
    let meta: ResponseMeta?
    let errors: [APIErrorDetail]?
}

struct HostDetailsResponse: Codable {
    let resources: [Host]?
    let meta: ResponseMeta?
    let errors: [APIErrorDetail]?
}

struct AlertsResponse: Codable {
    let resources: [String]?
    let meta: ResponseMeta?
    let errors: [APIErrorDetail]?
}

struct AlertDetailsResponse: Codable {
    let resources: [Alert]?
    let meta: ResponseMeta?
    let errors: [APIErrorDetail]?
}

struct ResponseMeta: Codable {
    let queryTime: Double?
    let pagination: Pagination?
    let poweredBy: String?
    let traceId: String?
    
    enum CodingKeys: String, CodingKey {
        case queryTime = "query_time"
        case pagination
        case poweredBy = "powered_by"
        case traceId = "trace_id"
    }
}

struct Pagination: Codable {
    let total: Int?
    let offset: Int?
    let limit: Int?
}

struct APIErrorDetail: Codable {
    let code: Int?
    let message: String?
    let id: String?
}

// MARK: - API Error Type

enum APIErrorType: Error, LocalizedError {
    case notAuthenticated
    case authenticationFailed(statusCode: Int, message: String)
    case invalidResponse
    case requestFailed(statusCode: Int, message: String)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated. Please log in."
        case .authenticationFailed(let statusCode, let message):
            return "Authentication failed (\(statusCode)): \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .requestFailed(let statusCode, let message):
            return "Request failed (\(statusCode)): \(message)"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - API Client

actor CrowdStrikeAPIClient {
    
    static let shared = CrowdStrikeAPIClient()
    
    private var configuration: AppConfiguration = .load()
    private var accessToken: String?
    private var tokenExpiration: Date?
    
    private let keychain = KeychainManager.shared
    
    private init() {}
    
    // MARK: - Configuration
    
    func updateConfiguration(_ config: AppConfiguration) {
        self.configuration = config
        accessToken = nil
        tokenExpiration = nil
    }
    
    func getConfiguration() -> AppConfiguration {
        return configuration
    }
    
    // MARK: - URL Session Configuration
    
    private func createURLSession() -> URLSession {
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.requestTimeout
        sessionConfig.timeoutIntervalForResource = configuration.requestTimeout * 2
        
        if configuration.proxy.isEnabled && !configuration.proxy.host.isEmpty {
            let proxyHost = configuration.proxy.host
            let proxyPort = configuration.proxy.port
            
            var proxyDict: [String: Any] = [
                "HTTPEnable": 1,
                "HTTPProxy": proxyHost,
                "HTTPPort": proxyPort,
                "HTTPSEnable": 1,
                "HTTPSProxy": proxyHost,
                "HTTPSPort": proxyPort
            ]
            
            if configuration.proxy.requiresAuth {
                proxyDict["HTTPUser"] = configuration.proxy.username
                proxyDict["HTTPPass"] = configuration.proxy.password
            }
            
            sessionConfig.connectionProxyDictionary = proxyDict
        }
        
        return URLSession(configuration: sessionConfig)
    }
    
    // MARK: - Helper Methods
    
    /// Properly encodes an FQL filter string for use in a URL query parameter.
    /// The + character (AND operator in FQL) must be encoded as %2B, otherwise
    /// it gets interpreted as a space by the server.
    private func encodeFQLFilter(_ filter: String) -> String {
        guard let encoded = filter.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return filter
        }
        // + must be %2B in URL query strings, otherwise it's interpreted as a space
        // Also encode = as %3D to avoid any ambiguity
        return encoded
            .replacingOccurrences(of: "+", with: "%2B")
            .replacingOccurrences(of: "=", with: "%3D")
    }
    
    // MARK: - Authentication
    
    func authenticate(clientId: String, clientSecret: String) async throws {
        var request = URLRequest(url: URL(string: "\(configuration.baseURLWithProtocol)/oauth2/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = configuration.connectionTimeout
        
        let body = "client_id=\(clientId)&client_secret=\(clientSecret)"
        request.httpBody = body.data(using: .utf8)
        
        let session = createURLSession()
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIErrorType.invalidResponse
        }
        
        guard httpResponse.statusCode == 201 || httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIErrorType.authenticationFailed(statusCode: httpResponse.statusCode, message: errorMessage)
        }
        
        let tokenResponse = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        
        guard let token = tokenResponse.accessToken, !token.isEmpty else {
            throw APIErrorType.authenticationFailed(statusCode: httpResponse.statusCode, message: "No access token in response")
        }
        
        let expiresIn = tokenResponse.expiresIn ?? 1800
        self.accessToken = token
        self.tokenExpiration = Date().addingTimeInterval(TimeInterval(expiresIn - 60))
        
        try await keychain.storeCredentials(clientId: clientId, clientSecret: clientSecret)
        try await keychain.deleteBearerToken()
    }
    
    func setBearerToken(_ token: String) async throws {
        self.accessToken = token
        self.tokenExpiration = Date().addingTimeInterval(3600)
        try await keychain.storeBearerToken(token)
        try await keychain.deleteCredentials()
    }
    
    func isAuthenticated() -> Bool {
        guard let token = accessToken, let expiration = tokenExpiration else { return false }
        return !token.isEmpty && Date() < expiration
    }
    
    func getStoredBearerToken() async -> String? {
        return try? await keychain.retrieveBearerToken()
    }
    
    private func ensureValidToken() async throws {
        if isAuthenticated() { return }
        
        switch configuration.authMethod {
        case .oauth:
            if let (clientId, clientSecret) = try? await keychain.retrieveCredentials() {
                try await authenticate(clientId: clientId, clientSecret: clientSecret)
            } else {
                throw APIErrorType.notAuthenticated
            }
        case .bearerToken:
            if let token = try? await keychain.retrieveBearerToken() {
                self.accessToken = token
                self.tokenExpiration = Date().addingTimeInterval(3600)
            } else {
                throw APIErrorType.notAuthenticated
            }
        }
    }
    
    // MARK: - Hosts API
    
    private func searchHostsPage(query: String?, offset: Int?, limit: Int) async throws -> (hostIds: [String], nextOffset: Int?, total: Int?) {
        try await ensureValidToken()
        
        // Build URL string manually to handle FQL filter encoding properly
        var urlString = "\(configuration.baseURLWithProtocol)/devices/queries/devices/v1?limit=\(limit)"
        
        if let query = query, !query.isEmpty {
            urlString += "&filter=\(encodeFQLFilter(query))"
        }
        if let offset = offset {
            urlString += "&offset=\(offset)"
        }
        
        guard let url = URL(string: urlString) else { throw APIErrorType.invalidResponse }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = configuration.requestTimeout
        
        let session = createURLSession()
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIErrorType.requestFailed(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                message: String(data: data, encoding: .utf8) ?? "Unknown error"
            )
        }
        
        let hostsResponse = try JSONDecoder().decode(HostsResponse.self, from: data)
        return (hostsResponse.resources ?? [], hostsResponse.meta?.pagination?.offset, hostsResponse.meta?.pagination?.total)
    }
    
    private func getHostDetailsBatch(hostIds: [String]) async throws -> [Host] {
        try await ensureValidToken()
        guard !hostIds.isEmpty else { return [] }
        
        var urlComponents = URLComponents(string: "\(configuration.baseURLWithProtocol)/devices/entities/devices/v2")!
        urlComponents.queryItems = hostIds.map { URLQueryItem(name: "ids", value: $0) }
        
        guard let url = urlComponents.url else { throw APIErrorType.invalidResponse }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = configuration.requestTimeout
        
        let session = createURLSession()
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIErrorType.requestFailed(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                message: String(data: data, encoding: .utf8) ?? "Unknown error"
            )
        }
        
        return (try? JSONDecoder().decode(HostDetailsResponse.self, from: data).resources) ?? []
    }
    
    func searchAndRetrieveHostsWithProgress(query: String?, progressHandler: @escaping (Int, Int) -> Void) async throws -> [Host] {
        try await ensureValidToken()
        
        // Build URL string manually to handle FQL filter encoding properly
        var countUrlString = "\(configuration.baseURLWithProtocol)/devices/queries/devices/v1?limit=1"
        if let query = query, !query.isEmpty {
            countUrlString += "&filter=\(encodeFQLFilter(query))"
        }
        
        guard let countUrl = URL(string: countUrlString) else { throw APIErrorType.invalidResponse }
        var countRequest = URLRequest(url: countUrl)
        countRequest.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        
        let session = createURLSession()
        let (countData, countResponse) = try await session.data(for: countRequest)
        
        guard let httpResponse = countResponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (countResponse as? HTTPURLResponse)?.statusCode ?? 0
            let message = String(data: countData, encoding: .utf8) ?? "Unknown error"
            throw APIErrorType.requestFailed(statusCode: statusCode, message: message)
        }
        
        let initialResponse = try JSONDecoder().decode(HostsResponse.self, from: countData)
        let totalCount = initialResponse.meta?.pagination?.total ?? 0
        
        print("Total host count: \(totalCount)")
        progressHandler(0, totalCount)
        
        if totalCount == 0 { return [] }
        
        var allHostIds: [String] = []
        var currentOffset: Int? = nil
        let limit = 500
        
        while true {
            let (hostIds, nextOffset, _) = try await searchHostsPage(query: query, offset: currentOffset, limit: limit)
            allHostIds.append(contentsOf: hostIds)
            currentOffset = nextOffset
            progressHandler(min(allHostIds.count, totalCount / 2), totalCount)
            
            if nextOffset == nil || hostIds.isEmpty {
                break
            }
        }
        
        print("Total host IDs fetched: \(allHostIds.count)")
        
        var allHosts: [Host] = []
        let batchSize = 100
        
        for i in stride(from: 0, to: allHostIds.count, by: batchSize) {
            let batchEnd = min(i + batchSize, allHostIds.count)
            let batchIds = Array(allHostIds[i..<batchEnd])
            
            let hosts = try await getHostDetailsBatch(hostIds: batchIds)
            allHosts.append(contentsOf: hosts)
            progressHandler(batchEnd, totalCount)
        }
        
        print("Total hosts retrieved: \(allHosts.count)")
        return allHosts
    }
    
    // MARK: - Alerts API
    
    func fetchAlerts(limit: Int = 500, minSeverity: Int? = 55, since: Date? = nil, filterThirdParty: Bool = true, progressHandler: @escaping (Int, Int) -> Void = { _, _ in }) async throws -> [Alert] {
        try await ensureValidToken()
        
        // Build filter string with + as AND operator in FQL
        var filters: [String] = []
        
        // Add severity filter
        // Note: severity is an integer field and must NOT be quoted
        if let minSeverity = minSeverity {
            filters.append("severity:>=\(minSeverity)")
        }
        
        // Add time filter for alerts created since the specified date (default: last 7 days)
        // Note: timestamps are string fields and MUST be quoted
        let sinceDate = since ?? Date().addingTimeInterval(-7 * 24 * 60 * 60)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        let sinceString = isoFormatter.string(from: sinceDate)
        filters.append("created_timestamp:>='\(sinceString)'")
        
        // Join filters with + (AND operator in FQL)
        let filterString = filters.joined(separator: "+")
        
        // Build URL string manually with proper FQL encoding
        let urlString = "\(configuration.baseURLWithProtocol)/alerts/queries/alerts/v2?limit=\(limit)&filter=\(encodeFQLFilter(filterString))"
        
        guard let url = URL(string: urlString) else { throw APIErrorType.invalidResponse }
        
        print("Alerts API URL: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = configuration.requestTimeout
        
        let session = createURLSession()
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIErrorType.requestFailed(
                statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                message: String(data: data, encoding: .utf8) ?? "Unknown error"
            )
        }
        
        let alertsResponse = try JSONDecoder().decode(AlertsResponse.self, from: data)
        guard let alertIds = alertsResponse.resources, !alertIds.isEmpty else {
            print("No alert IDs returned")
            progressHandler(0, 0)
            return []
        }
        
        print("Fetched \(alertIds.count) total alert IDs from API")
        
        // Filter out third-party alerts if user has selected that option
        let filteredIds: [String]
        if filterThirdParty {
            let thirdPartyCount = alertIds.filter { $0.contains(":thirdparty:") }.count
            filteredIds = alertIds.filter { !$0.contains(":thirdparty:") }
            print("Filtering enabled: \(thirdPartyCount) third-party alerts removed, \(filteredIds.count) remaining")
        } else {
            filteredIds = alertIds
            print("Filtering disabled: keeping all \(filteredIds.count) alerts")
        }
        
        let totalCount = filteredIds.count
        progressHandler(0, totalCount)
        
        guard !filteredIds.isEmpty else {
            print("No non-third-party alerts to fetch")
            return []
        }
        
        var allAlerts: [Alert] = []
        let batchSize = 50
        var errorCount = 0
        
        for i in stride(from: 0, to: filteredIds.count, by: batchSize) {
            try Task.checkCancellation()
            
            let batchEnd = min(i + batchSize, filteredIds.count)
            let batchIds = Array(filteredIds[i..<batchEnd])
            
            print("Fetching alert batch \(i/batchSize + 1): IDs \(i) to \(batchEnd)")
            
            let detailsUrl = URL(string: "\(configuration.baseURLWithProtocol)/alerts/entities/alerts/v2")!
            
            var detailsRequest = URLRequest(url: detailsUrl)
            detailsRequest.httpMethod = "POST"
            detailsRequest.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
            detailsRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = ["composite_ids": batchIds]
            detailsRequest.httpBody = try? JSONSerialization.data(withJSONObject: body)
            detailsRequest.timeoutInterval = configuration.requestTimeout
            
            do {
                let (detailsData, detailsResponse) = try await session.data(for: detailsRequest)
                let statusCode = (detailsResponse as? HTTPURLResponse)?.statusCode ?? 0
                
                if statusCode == 200 {
                    let decoder = JSONDecoder()
                    do {
                        let alertDetailsResponse = try decoder.decode(AlertDetailsResponse.self, from: detailsData)
                        if let alerts = alertDetailsResponse.resources {
                            allAlerts.append(contentsOf: alerts)
                            print("Successfully decoded \(alerts.count) alerts in this batch")
                        } else {
                            print("No resources in alert details response")
                        }
                    } catch {
                        print("Failed to decode alert details: \(error)")
                        errorCount += 1
                    }
                    progressHandler(batchEnd, totalCount)
                } else {
                    print("Alert details fetch returned status code: \(statusCode)")
                    if let responseString = String(data: detailsData, encoding: .utf8) {
                        print("Error response: \(responseString)")
                    }
                    errorCount += 1
                }
            } catch URLError.cancelled {
                print("Alert fetch cancelled")
                throw APIErrorType.networkError(URLError(.cancelled))
            } catch {
                print("Alert fetch error: \(error.localizedDescription)")
                errorCount += 1
            }
        }
        
        // Client-side severity filter as fallback (in case API filter doesn't work as expected)
        if let minSeverity = minSeverity {
            let beforeCount = allAlerts.count
            allAlerts = allAlerts.filter { ($0.severity ?? 0) >= minSeverity }
            let filteredCount = beforeCount - allAlerts.count
            if filteredCount > 0 {
                print("Client-side severity filter removed \(filteredCount) alerts below severity \(minSeverity)")
            }
        }
        
        print("Total alerts retrieved: \(allAlerts.count), errors encountered: \(errorCount)")
        return allAlerts
    }
    
    // MARK: - Connection Test
    
    func testConnection() async throws -> Bool {
        try await ensureValidToken()
        
        var urlComponents = URLComponents(string: "\(configuration.baseURLWithProtocol)/devices/queries/devices/v1")!
        urlComponents.queryItems = [URLQueryItem(name: "limit", value: "1")]
        
        guard let url = urlComponents.url else { throw APIErrorType.invalidResponse }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = configuration.connectionTimeout
        
        let session = createURLSession()
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIErrorType.invalidResponse
        }
        
        return httpResponse.statusCode == 200
    }
}

// MARK: - Date Extension
extension Date {
    func timeAgoString() -> String {
        let interval = Date().timeIntervalSince(self)
        return Date.timeAgoString(from: interval)
    }
    
    static func timeAgoString(from interval: TimeInterval) -> String {
        let seconds = Int(interval)
        if seconds < 0 { return "in the future" }
        if seconds < 60 { return "\(seconds) sec ago" }
        
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes) min ago" }
        
        let hours = minutes / 60
        if hours < 24 {
            let remainingMinutes = minutes % 60
            return remainingMinutes == 0 ? "\(hours) hr ago" : "\(hours) hr \(remainingMinutes) min ago"
        }
        
        let days = hours / 24
        if days < 7 {
            let remainingHours = hours % 24
            return remainingHours == 0 ? "\(days) day\(days == 1 ? "" : "s") ago" : "\(days) day\(days == 1 ? "" : "s") \(remainingHours) hr ago"
        }
        return "\(days) days ago"
    }
}
