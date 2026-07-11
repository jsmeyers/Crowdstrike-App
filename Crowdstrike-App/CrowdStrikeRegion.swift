//
//  CrowdStrikeRegion.swift
//  Crowdstrike-App
//

import Foundation

nonisolated enum CrowdStrikeRegion: String, CaseIterable, Identifiable, Codable, Sendable {
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
