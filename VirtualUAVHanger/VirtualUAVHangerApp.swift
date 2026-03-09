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

    @StateObject private var authManager: AuthManager = {
        // Clear auth state when running UI tests so login screen is always shown first.
        if CommandLine.arguments.contains("--reset-auth") {
            UserDefaults.standard.removeObject(forKey: "vhangar.session")
        }
        return AuthManager()
    }()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Hangar.self,
            Drone.self,
            DronePart.self
        ])
        // UI tests use an in-memory store so each run starts clean.
        let isUITesting = CommandLine.arguments.contains("--uitesting")
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isUITesting
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
                    .task {
                        if CommandLine.arguments.contains("--seed-pyrodrone") {
                            await seedPyrodroneData()
                        }
                    }
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
    }

    // MARK: - Pyrodrone Seed (UI-test helper)

    @MainActor
    private func seedPyrodroneData() async {
        let ctx = sharedModelContainer.mainContext
        let hangar = Hangar(name: "Pyrodrone Demo Hangar")
        ctx.insert(hangar)

        let drones = PyrodroneSeedCatalog.entries.filter { $0.kind == .drone }.prefix(5)
        for entry in drones {
            let drone = Drone(name: entry.name, hangar: hangar)
            ctx.insert(drone)
        }

        let firstDrone = hangar.drones.first
        let parts = PyrodroneSeedCatalog.entries.filter { $0.kind == .part }.prefix(8)
        for entry in parts {
            let part = DronePart(
                name: entry.name,
                category: entry.category ?? .motor,
                brand: entry.brand ?? "",
                quantity: entry.quantity ?? 1,
                manualURL: entry.productURL,
                drone: firstDrone
            )
            ctx.insert(part)
        }

        try? ctx.save()
    }
}
