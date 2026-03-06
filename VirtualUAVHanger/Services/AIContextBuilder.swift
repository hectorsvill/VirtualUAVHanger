//
//  AIContextBuilder.swift
//  VirtualUAVHanger
//
//  Builds a compact inventory snapshot to send to the AI assistant.
//

import Foundation
import SwiftData

enum AIContextBuilder {
    static func snapshot(modelContext: ModelContext, maxDrones: Int = 50, maxParts: Int = 150) -> String {
        let drones = (try? modelContext.fetch(FetchDescriptor<Drone>(sortBy: [SortDescriptor(\.name)]))) ?? []
        let parts = (try? modelContext.fetch(FetchDescriptor<DronePart>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]))) ?? []

        var lines: [String] = []
        lines.append("Inventory Snapshot (local-first). Treat app as ONE hangar.")
        lines.append("Drones: \(drones.count)")
        for drone in drones.prefix(maxDrones) {
            lines.append("- drone {id=\(drone.id.uuidString), name=\"\(drone.name)\", parts=\(drone.parts.count)}")
        }
        if drones.count > maxDrones {
            lines.append("- ... \(drones.count - maxDrones) more drones")
        }

        lines.append("Components: \(parts.count)")
        for part in parts.prefix(maxParts) {
            let droneName = part.drone?.name ?? ""
            lines.append("- part {id=\(part.id.uuidString), name=\"\(part.name)\", category=\(part.category.rawValue), brand=\"\(part.brand)\", serial=\"\(part.serialNumber)\", qty=\(part.quantity), status=\(part.status.rawValue), drone=\"\(droneName)\"}")
        }
        if parts.count > maxParts {
            lines.append("- ... \(parts.count - maxParts) more parts")
        }
        return lines.joined(separator: "\n")
    }
}

