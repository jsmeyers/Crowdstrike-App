//
//  DateUtilities.swift
//  Crowdstrike-App
//

import Foundation

nonisolated enum DateUtilities {
    static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    static let iso8601WithoutFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    static func parseISO8601Date(_ string: String) -> Date? {
        if let date = iso8601WithFractional.date(from: string) { return date }
        return iso8601WithoutFractional.date(from: string)
    }
}

nonisolated extension Date {
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
