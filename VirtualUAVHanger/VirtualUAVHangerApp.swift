//
//  VirtualUAVHangerApp.swift
//  VirtualUAVHanger
//
//  Created by Hector Steven Villasano on 3/5/26.
//

import SwiftData
import SwiftUI

@main
struct VirtualUAVHangerApp: App {

    @StateObject private var authManager = AuthManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Hangar.self,
            Drone.self,
            DronePart.self
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData ModelContainer failed: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .modelContainer(sharedModelContainer)
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }
}
