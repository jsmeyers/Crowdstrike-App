//
//  Crowdstrike_AppApp.swift
//  Crowdstrike-App
//
//  Created by scotteberg@gmail.com on 2/22/26.
//

import SwiftUI
import SwiftData

@main
struct Crowdstrike_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [HostEntity.self, AlertEntity.self])
    }
}
