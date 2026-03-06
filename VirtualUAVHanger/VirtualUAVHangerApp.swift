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
            ContentView()
                .modelContainer(sharedModelContainer)
        }
    }
}
