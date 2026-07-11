import Foundation

// MARK: - OAuth Token Response
nonisolated struct OAuthTokenResponse: Codable, Sendable {
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
nonisolated struct Host: Identifiable, Codable, Hashable, Sendable {
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
        case hostname, localIp = "local_ip", externalIp = "external_ip", macAddress = "mac_address"
        case osVersion = "os_version", osProductName = "os_product_name", platformName = "platform_name"
        case status, lastSeen = "last_seen", firstSeen = "first_seen", country, city
        case agentVersion = "agent_version", ou, groups, cid
        case majorVersion = "major_version", minorVersion = "minor_version", buildNumber = "build_number"
        case machineDomain = "machine_domain", siteName = "site_name"
        case lastLoginUser = "last_login_user", lastLoginTimestamp = "last_login_timestamp"
        case productType = "product_type", productTypeDesc = "product_type_desc"
        case systemManufacturer = "system_manufacturer", systemProductName = "system_product_name"
        case serialNumber = "serial_number", chassisType = "chassis_type", chassisTypeDesc = "chassis_type_desc"
        case connectionIp = "connection_ip", defaultGatewayIp = "default_gateway_ip", tags
    }
    
    init(id: String, hostname: String? = nil, localIp: String? = nil, externalIp: String? = nil, macAddress: String? = nil, osVersion: String? = nil, osProductName: String? = nil, platformName: String? = nil, status: String? = nil, lastSeen: String? = nil, firstSeen: String? = nil, country: String? = nil, city: String? = nil, agentVersion: String? = nil, ou: String? = nil, groups: [HostGroup]? = nil) {
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
    
    private static func fallbackIdentifier(hostname: String?, localIp: String?, externalIp: String?, macAddress: String?, firstSeen: String?) -> String {
        let parts = [hostname, localIp, externalIp, macAddress, firstSeen].compactMap { $0?.isEmpty == false ? $0 : nil }
        if parts.isEmpty { return "unknown-empty" }
        return "unknown:" + parts.joined(separator: "|")
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let deviceId = try? c.decode(String.self, forKey: .id) {
            id = deviceId
        } else if let deviceIdInt = try? c.decode(Int.self, forKey: .id) {
            id = String(deviceIdInt)
        } else {
            let hn = try? c.decodeIfPresent(String.self, forKey: .hostname)
            let lip = try? c.decodeIfPresent(String.self, forKey: .localIp)
            let eip = try? c.decodeIfPresent(String.self, forKey: .externalIp)
            let mac = try? c.decodeIfPresent(String.self, forKey: .macAddress)
            let fs = try? c.decodeIfPresent(String.self, forKey: .firstSeen)
            id = Self.fallbackIdentifier(hostname: hn, localIp: lip, externalIp: eip, macAddress: mac, firstSeen: fs)
        }
        hostname = try c.decodeIfPresent(String.self, forKey: .hostname)
        localIp = try c.decodeIfPresent(String.self, forKey: .localIp)
        externalIp = try c.decodeIfPresent(String.self, forKey: .externalIp)
        macAddress = try c.decodeIfPresent(String.self, forKey: .macAddress)
        osVersion = try c.decodeIfPresent(String.self, forKey: .osVersion)
        osProductName = try c.decodeIfPresent(String.self, forKey: .osProductName)
        platformName = try c.decodeIfPresent(String.self, forKey: .platformName)
        status = try c.decodeIfPresent(String.self, forKey: .status)
        lastSeen = try c.decodeIfPresent(String.self, forKey: .lastSeen)
        firstSeen = try c.decodeIfPresent(String.self, forKey: .firstSeen)
        country = try c.decodeIfPresent(String.self, forKey: .country)
        city = try c.decodeIfPresent(String.self, forKey: .city)
        agentVersion = try c.decodeIfPresent(String.self, forKey: .agentVersion)
        
        if let ouString = try? c.decodeIfPresent(String.self, forKey: .ou) {
            ou = ouString.isEmpty ? nil : ouString
            ouList = ouString.isEmpty ? nil : [ouString]
        } else if let ouArray = try? c.decodeIfPresent([String].self, forKey: .ou) {
            ouList = ouArray.isEmpty ? nil : ouArray
            ou = ouArray.isEmpty ? nil : ouArray.joined(separator: ", ")
        } else {
            ou = nil
            ouList = nil
        }
        
        if let groupObjects = try? c.decodeIfPresent([HostGroup].self, forKey: .groups) {
            groups = groupObjects
            groupIds = nil
        } else if let groupArray = try? c.decodeIfPresent([String].self, forKey: .groups) {
            groupIds = groupArray
            groups = groupArray.map { HostGroup(id: $0, name: nil) }
        } else {
            groups = nil
            groupIds = nil
        }
        
        cid = try c.decodeIfPresent(String.self, forKey: .cid)
        majorVersion = try c.decodeIfPresent(String.self, forKey: .majorVersion)
        minorVersion = try c.decodeIfPresent(String.self, forKey: .minorVersion)
        buildNumber = try c.decodeIfPresent(String.self, forKey: .buildNumber)
        machineDomain = try c.decodeIfPresent(String.self, forKey: .machineDomain)
        siteName = try c.decodeIfPresent(String.self, forKey: .siteName)
        lastLoginUser = try c.decodeIfPresent(String.self, forKey: .lastLoginUser)
        lastLoginTimestamp = try c.decodeIfPresent(String.self, forKey: .lastLoginTimestamp)
        productType = try c.decodeIfPresent(String.self, forKey: .productType)
        productTypeDesc = try c.decodeIfPresent(String.self, forKey: .productTypeDesc)
        systemManufacturer = try c.decodeIfPresent(String.self, forKey: .systemManufacturer)
        systemProductName = try c.decodeIfPresent(String.self, forKey: .systemProductName)
        serialNumber = try c.decodeIfPresent(String.self, forKey: .serialNumber)
        chassisType = try c.decodeIfPresent(String.self, forKey: .chassisType)
        chassisTypeDesc = try c.decodeIfPresent(String.self, forKey: .chassisTypeDesc)
        connectionIp = try c.decodeIfPresent(String.self, forKey: .connectionIp)
        defaultGatewayIp = try c.decodeIfPresent(String.self, forKey: .defaultGatewayIp)
        tags = try c.decodeIfPresent([String].self, forKey: .tags)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(hostname, forKey: .hostname)
        try c.encodeIfPresent(localIp, forKey: .localIp)
        try c.encodeIfPresent(externalIp, forKey: .externalIp)
        try c.encodeIfPresent(macAddress, forKey: .macAddress)
        try c.encodeIfPresent(osVersion, forKey: .osVersion)
        try c.encodeIfPresent(osProductName, forKey: .osProductName)
        try c.encodeIfPresent(platformName, forKey: .platformName)
        try c.encodeIfPresent(status, forKey: .status)
        try c.encodeIfPresent(lastSeen, forKey: .lastSeen)
        try c.encodeIfPresent(firstSeen, forKey: .firstSeen)
        try c.encodeIfPresent(country, forKey: .country)
        try c.encodeIfPresent(city, forKey: .city)
        try c.encodeIfPresent(agentVersion, forKey: .agentVersion)
        try c.encodeIfPresent(ouList, forKey: .ou)
        try c.encodeIfPresent(groupIds, forKey: .groups)
        try c.encodeIfPresent(cid, forKey: .cid)
        try c.encodeIfPresent(majorVersion, forKey: .majorVersion)
        try c.encodeIfPresent(minorVersion, forKey: .minorVersion)
        try c.encodeIfPresent(buildNumber, forKey: .buildNumber)
        try c.encodeIfPresent(machineDomain, forKey: .machineDomain)
        try c.encodeIfPresent(siteName, forKey: .siteName)
        try c.encodeIfPresent(lastLoginUser, forKey: .lastLoginUser)
        try c.encodeIfPresent(lastLoginTimestamp, forKey: .lastLoginTimestamp)
        try c.encodeIfPresent(productType, forKey: .productType)
        try c.encodeIfPresent(productTypeDesc, forKey: .productTypeDesc)
        try c.encodeIfPresent(systemManufacturer, forKey: .systemManufacturer)
        try c.encodeIfPresent(systemProductName, forKey: .systemProductName)
        try c.encodeIfPresent(serialNumber, forKey: .serialNumber)
        try c.encodeIfPresent(chassisType, forKey: .chassisType)
        try c.encodeIfPresent(chassisTypeDesc, forKey: .chassisTypeDesc)
        try c.encodeIfPresent(connectionIp, forKey: .connectionIp)
        try c.encodeIfPresent(defaultGatewayIp, forKey: .defaultGatewayIp)
        try c.encodeIfPresent(tags, forKey: .tags)
    }
    
    var displayName: String { hostname ?? "Unknown Host" }
    
    var searchableFields: [String] {
        var fields: [String] = [displayName.lowercased()]
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
    
    var lastSeenDate: Date? {
        guard let lastSeen = lastSeen else { return nil }
        return DateUtilities.parseISO8601Date(lastSeen)
    }
    
    var firstSeenDate: Date? {
        guard let firstSeen = firstSeen else { return nil }
        return DateUtilities.parseISO8601Date(firstSeen)
    }
    
    var lastLoginDate: Date? {
        guard let lastLoginTimestamp = lastLoginTimestamp else { return nil }
        return DateUtilities.parseISO8601Date(lastLoginTimestamp)
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

nonisolated struct HostGroup: Codable, Hashable, Sendable {
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
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
    }
}

// MARK: - Alert Models
nonisolated struct AlertDevice: Codable, Sendable {
    let deviceId: String?
    let hostname: String?
    let localIp: String?
    let externalIp: String?
    let macAddress: String?
    let osVersion: String?
    let platformName: String?
    let status: String?
    let lastSeen: String?
    let firstSeen: String?
    let country: String?
    let city: String?
    let agentVersion: String?
    let machineDomain: String?
    let siteName: String?
    let productType: String?
    let productTypeDesc: String?
    let systemManufacturer: String?
    let systemProductName: String?
    let majorVersion: String?
    let minorVersion: String?
    let cid: String?
    let ou: [String]?
    let groups: [String]?
    let tags: [String]?
    
    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id", hostname, localIp = "local_ip", externalIp = "external_ip", macAddress = "mac_address"
        case osVersion = "os_version", platformName = "platform_name", status, lastSeen = "last_seen", firstSeen = "first_seen"
        case country, city, agentVersion = "agent_version", machineDomain = "machine_domain", siteName = "site_name"
        case productType = "product_type", productTypeDesc = "product_type_desc"
        case systemManufacturer = "system_manufacturer", systemProductName = "system_product_name"
        case majorVersion = "major_version", minorVersion = "minor_version", cid, ou, groups, tags
    }
}

nonisolated struct AlertProcessDetails: Codable, Sendable {
    let sha256: String?
    let md5: String?
    let filename: String?
    let filepath: String?
    let cmdline: String?
    let processId: String?
    let localProcessId: String?
    let userId: String?
    let userName: String?
    let timestamp: String?
    
    enum CodingKeys: String, CodingKey {
        case sha256, md5, filename, filepath, cmdline
        case processId = "process_id", localProcessId = "local_process_id", userId = "user_id", userName = "user_name", timestamp
    }
}

nonisolated struct Alert: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String?
    let description: String?
    let severity: Int?
    let status: String?
    let createdTime: String?
    let updatedTime: String?
    let tactic: String?
    let technique: String?
    let tacticId: String?
    let techniqueId: String?
    let cid: String?
    let type: String?
    let scenario: String?
    let objective: String?
    let patternId: String?
    let confidence: Int?
    let severityName: String?
    let startTime: String?
    let endTime: String?
    
    let fileName: String?
    let filePath: String?
    let sha256: String?
    let md5: String?
    let commandLine: String?
    let processId: String?
    let localProcessId: String?
    let userId: String?
    let userName: String?
    
    let parentDetails: AlertProcessDetails?
    let grandparentDetails: AlertProcessDetails?
    
    let localIp: String?
    let localPort: Int?
    let remoteIp: String?
    let remotePort: Int?
    let networkProtocol: String?
    let networkDirection: String?
    
    let country: String?
    let city: String?
    let rootSite: String?
    let siteId: String?
    let rootMachineDomain: String?
    let rootOu: String?
    
    let tags: [String]?
    let hostGroups: [String]?
    let assignedTo: String?
    let assignedToName: String?
    let policyId: String?
    let policyName: String?
    
    let device: AlertDevice?
    let compositeId: String?
    let agentId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, severity, status
        case createdTime = "created_timestamp", updatedTime = "updated_timestamp"
        case tactic, technique, tacticId = "tactic_id", techniqueId = "technique_id"
        case cid, type, scenario, objective, patternId = "pattern_id", confidence, severityName = "severity_name"
        case startTime = "timestamp", endTime = "process_end_time"
        case fileName = "filename", filePath = "filepath", sha256, md5, commandLine = "cmdline"
        case processId = "parent_process_id", localProcessId = "local_process_id", userId = "user_id", userName = "user_name"
        case parentDetails = "parent_details", grandparentDetails = "grandparent_details"
        case localIp = "local_ip", localPort = "local_port", remoteIp = "remote_ip", remotePort = "remote_port", networkProtocol = "protocol", networkDirection
        case country, city, rootSite = "site", siteId = "site_id", rootMachineDomain = "machine_domain", rootOu = "ou"
        case tags, hostGroups = "host_groups", assignedTo = "assigned_to", assignedToName = "assigned_to_name", policyId = "policy_id", policyName = "policy_name"
        case device, compositeId = "composite_id", agentId = "agent_id"
    }
    
    private static func fallbackIdentifier(name: String?, createdTime: String?, deviceId: String?, severity: Int?) -> String {
        var parts: [String] = []
        if let name, !name.isEmpty { parts.append(name) }
        if let createdTime, !createdTime.isEmpty { parts.append(createdTime) }
        if let deviceId, !deviceId.isEmpty { parts.append(deviceId) }
        if let severity { parts.append(String(severity)) }
        if parts.isEmpty { return "unknown-empty" }
        return "unknown:" + parts.joined(separator: "|")
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        compositeId = try c.decodeIfPresent(String.self, forKey: .compositeId)
        if let compositeId = compositeId {
            id = compositeId
        } else if let idString = try? c.decode(String.self, forKey: .id) {
            id = idString
        } else if let idInt = try? c.decode(Int.self, forKey: .id) {
            id = String(idInt)
        } else {
            let n = try? c.decodeIfPresent(String.self, forKey: .name)
            let ct = try? c.decodeIfPresent(String.self, forKey: .createdTime)
            let dev = try? c.decodeIfPresent(AlertDevice.self, forKey: .device)
            let sev = try? c.decodeIfPresent(Int.self, forKey: .severity)
            id = Self.fallbackIdentifier(name: n, createdTime: ct, deviceId: dev?.deviceId, severity: sev)
        }
        agentId = try c.decodeIfPresent(String.self, forKey: .agentId)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        severity = try c.decodeIfPresent(Int.self, forKey: .severity)
        status = try c.decodeIfPresent(String.self, forKey: .status)
        createdTime = try c.decodeIfPresent(String.self, forKey: .createdTime)
        updatedTime = try c.decodeIfPresent(String.self, forKey: .updatedTime)
        tactic = try c.decodeIfPresent(String.self, forKey: .tactic)
        technique = try c.decodeIfPresent(String.self, forKey: .technique)
        tacticId = try c.decodeIfPresent(String.self, forKey: .tacticId)
        techniqueId = try c.decodeIfPresent(String.self, forKey: .techniqueId)
        cid = try c.decodeIfPresent(String.self, forKey: .cid)
        type = try c.decodeIfPresent(String.self, forKey: .type)
        scenario = try c.decodeIfPresent(String.self, forKey: .scenario)
        objective = try c.decodeIfPresent(String.self, forKey: .objective)
        
        if let patternIdString = try? c.decodeIfPresent(String.self, forKey: .patternId) {
            patternId = patternIdString
        } else if let patternIdInt = try? c.decodeIfPresent(Int.self, forKey: .patternId) {
            patternId = String(patternIdInt)
        } else {
            patternId = nil
        }
        
        confidence = try c.decodeIfPresent(Int.self, forKey: .confidence)
        severityName = try c.decodeIfPresent(String.self, forKey: .severityName)
        startTime = try c.decodeIfPresent(String.self, forKey: .startTime)
        endTime = try c.decodeIfPresent(String.self, forKey: .endTime)
        
        fileName = try c.decodeIfPresent(String.self, forKey: .fileName)
        filePath = try c.decodeIfPresent(String.self, forKey: .filePath)
        sha256 = try c.decodeIfPresent(String.self, forKey: .sha256)
        md5 = try c.decodeIfPresent(String.self, forKey: .md5)
        commandLine = try c.decodeIfPresent(String.self, forKey: .commandLine)
        processId = try c.decodeIfPresent(String.self, forKey: .processId)
        localProcessId = try c.decodeIfPresent(String.self, forKey: .localProcessId)
        userId = try c.decodeIfPresent(String.self, forKey: .userId)
        userName = try c.decodeIfPresent(String.self, forKey: .userName)
        
        parentDetails = try c.decodeIfPresent(AlertProcessDetails.self, forKey: .parentDetails)
        grandparentDetails = try c.decodeIfPresent(AlertProcessDetails.self, forKey: .grandparentDetails)
        
        localIp = try c.decodeIfPresent(String.self, forKey: .localIp)
        localPort = try c.decodeIfPresent(Int.self, forKey: .localPort)
        remoteIp = try c.decodeIfPresent(String.self, forKey: .remoteIp)
        remotePort = try c.decodeIfPresent(Int.self, forKey: .remotePort)
        networkProtocol = try c.decodeIfPresent(String.self, forKey: .networkProtocol)
        networkDirection = try c.decodeIfPresent(String.self, forKey: .networkDirection)
        
        country = try c.decodeIfPresent(String.self, forKey: .country)
        city = try c.decodeIfPresent(String.self, forKey: .city)
        rootSite = try c.decodeIfPresent(String.self, forKey: .rootSite)
        siteId = try c.decodeIfPresent(String.self, forKey: .siteId)
        rootMachineDomain = try c.decodeIfPresent(String.self, forKey: .rootMachineDomain)
        rootOu = try c.decodeIfPresent(String.self, forKey: .rootOu)
        
        tags = try c.decodeIfPresent([String].self, forKey: .tags)
        hostGroups = try c.decodeIfPresent([String].self, forKey: .hostGroups)
        assignedTo = try c.decodeIfPresent(String.self, forKey: .assignedTo)
        assignedToName = try c.decodeIfPresent(String.self, forKey: .assignedToName)
        policyId = try c.decodeIfPresent(String.self, forKey: .policyId)
        policyName = try c.decodeIfPresent(String.self, forKey: .policyName)
        
        device = try c.decodeIfPresent(AlertDevice.self, forKey: .device)
    }
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Alert, rhs: Alert) -> Bool { lhs.id == rhs.id }
    
    var hostname: String? { device?.hostname }
    var deviceId: String? { device?.deviceId }
    var platform: String? { device?.platformName }
    var osVersion: String? { device?.osVersion }
    
    static func parseISO8601Date(_ string: String) -> Date? { DateUtilities.parseISO8601Date(string) }
    
    var createdDate: Date? {
        guard let createdTime = createdTime else { return nil }
        return Self.parseISO8601Date(createdTime)
    }
    
    var updatedDate: Date? {
        guard let updatedTime = updatedTime else { return nil }
        return Self.parseISO8601Date(updatedTime)
    }
    
    var startDate: Date? {
        guard let startTime = startTime else { return nil }
        return Self.parseISO8601Date(startTime)
    }
    
    var endDate: Date? {
        guard let endTime = endTime else { return nil }
        return Self.parseISO8601Date(endTime)
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
    
    var statusColor: String {
        switch status?.lowercased() {
        case "new": return "red"
        case "in_progress", "in progress": return "orange"
        case "closed": return "green"
        case "reopened": return "yellow"
        default: return "gray"
        }
    }
    
    var detectionSourceText: String { return "CrowdStrike Falcon" }
    var isNetworkAlert: Bool { localIp != nil || remoteIp != nil || localPort != nil || remotePort != nil }
    var hasProcessInfo: Bool { fileName != nil || commandLine != nil || processId != nil || parentDetails != nil }
    var hasHostInfo: Bool { device != nil || hostname != nil || deviceId != nil || platform != nil || osVersion != nil }
    var parentFileName: String? { parentDetails?.filename }
    var parentCommandLine: String? { parentDetails?.cmdline }
    
    var locationText: String? {
        if let device = device {
            var parts: [String] = []
            if let city = device.city, !city.isEmpty { parts.append(city) }
            if let country = device.country, !country.isEmpty { parts.append(country) }
            if !parts.isEmpty { return parts.joined(separator: ", ") }
        }
        var parts: [String] = []
        if let city = city, !city.isEmpty { parts.append(city) }
        if let country = country, !country.isEmpty { parts.append(country) }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
    
    var username: String? { userName ?? parentDetails?.userName }
    var site: String? { rootSite ?? device?.siteName }
    var machineDomain: String? { rootMachineDomain ?? device?.machineDomain }
    
    var ou: String? {
        if let rootOu = rootOu, !rootOu.isEmpty { return rootOu }
        if let deviceOu = device?.ou, !deviceOu.isEmpty { return deviceOu.joined(separator: ", ") }
        return nil
    }
}

nonisolated extension Alert {
    static func isThirdPartyAlertId(_ id: String) -> Bool {
        id.contains(":thirdparty:")
    }
}

// MARK: - API Response Models
nonisolated struct HostsResponse: Codable, Sendable {
    let resources: [String]?
    let meta: ResponseMeta?
    let errors: [APIErrorDetail]?
}

nonisolated struct HostDetailsResponse: Codable, Sendable {
    let resources: [Host]?
    let meta: ResponseMeta?
    let errors: [APIErrorDetail]?
}

nonisolated struct AlertsResponse: Codable, Sendable {
    let resources: [String]?
    let meta: ResponseMeta?
    let errors: [APIErrorDetail]?
}

nonisolated struct AlertDetailsResponse: Codable, Sendable {
    let resources: [Alert]?
    let meta: ResponseMeta?
    let errors: [APIErrorDetail]?
}

nonisolated struct ResponseMeta: Codable, Sendable {
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

nonisolated struct Pagination: Codable, Sendable {
    let total: Int?
    let offset: Int?
    let limit: Int?
    let after: String?
}

nonisolated struct APIErrorDetail: Codable, Sendable {
    let code: Int?
    let message: String?
    let id: String?
}

// MARK: - API Error Type
nonisolated enum APIError: Error, LocalizedError, Sendable {
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

