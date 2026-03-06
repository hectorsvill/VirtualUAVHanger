//
//  AIActionExecutor.swift
//  VirtualUAVHanger
//
//  Applies AI-generated actions to SwiftData entities.
//

import Foundation
import SwiftData

enum AIActionExecutor {
    struct Result {
        var applied: Int
        var failures: [String]
    }

    static func apply(
        envelope: AIActionEnvelope,
        modelContext: ModelContext,
        partRepository: PartRepositoryProtocol
    ) -> Result {
        var applied = 0
        var failures: [String] = []

        for action in envelope.actions {
            do {
                try applyOne(action, modelContext: modelContext, partRepository: partRepository)
                applied += 1
            } catch {
                failures.append("\(action.type): \(error.localizedDescription)")
            }
        }

        return Result(applied: applied, failures: failures)
    }

    private static func applyOne(
        _ action: AIAction,
        modelContext: ModelContext,
        partRepository: PartRepositoryProtocol
    ) throws {
        switch action.type {
        case "createDrone":
            let name = action.fields?["name"]?.stringValue?.trimmedNonEmpty ?? "New Drone"
            let imageURL = action.fields?["imageURL"]?.stringValue?.trimmedNonEmpty
            let drone = Drone(name: name, hangar: nil, imageURL: imageURL, localImagePath: nil)
            modelContext.insert(drone)
            try modelContext.save()

        case "updateDrone":
            guard let drone = try findDrone(action: action, modelContext: modelContext) else {
                throw NSError(domain: "AIActionExecutor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Drone not found"])
            }
            if let name = action.fields?["name"]?.stringValue?.trimmedNonEmpty {
                drone.name = name
            }
            if let imageURL = action.fields?["imageURL"]?.stringValue?.trimmedNonEmpty {
                drone.imageURL = imageURL
                drone.localImagePath = nil
            }
            drone.updatedAt = .now
            try modelContext.save()

        case "deleteDrone":
            guard let drone = try findDrone(action: action, modelContext: modelContext) else {
                throw NSError(domain: "AIActionExecutor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Drone not found"])
            }
            modelContext.delete(drone)
            try modelContext.save()

        case "createPart":
            let name = action.fields?["name"]?.stringValue?.trimmedNonEmpty ?? "Untitled Part"
            let brand = action.fields?["brand"]?.stringValue?.trimmedNonEmpty ?? "Unknown"
            let serial = action.fields?["serialNumber"]?.stringValue ?? ""
            let manualURL = action.fields?["manualURL"]?.stringValue?.trimmedNonEmpty
            let imageURL = action.fields?["imageURL"]?.stringValue?.trimmedNonEmpty
            let qty = max(1, action.fields?["quantity"]?.intValue ?? 1)
            let status = PartStatus(rawValue: action.fields?["status"]?.stringValue ?? "") ?? .spare
            let category = PartCategory(rawValue: action.fields?["category"]?.stringValue ?? "") ?? .motor

            let drone = try findDroneFromFields(action: action, modelContext: modelContext)

            let part = DronePart(
                name: name,
                category: category,
                brand: brand,
                serialNumber: serial,
                quantity: qty,
                manualURL: manualURL,
                imageURL: imageURL,
                localImagePath: nil,
                status: status,
                drone: drone
            )
            try partRepository.create(part)

        case "updatePart":
            guard let part = try findPart(action: action, modelContext: modelContext) else {
                throw NSError(domain: "AIActionExecutor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Part not found"])
            }
            if let name = action.fields?["name"]?.stringValue?.trimmedNonEmpty { part.name = name }
            if let brand = action.fields?["brand"]?.stringValue?.trimmedNonEmpty { part.brand = brand }
            if let serial = action.fields?["serialNumber"]?.stringValue { part.serialNumber = serial }
            if let manualURL = action.fields?["manualURL"]?.stringValue?.trimmedNonEmpty { part.manualURL = manualURL }
            if let imageURL = action.fields?["imageURL"]?.stringValue?.trimmedNonEmpty {
                part.imageURL = imageURL
                part.localImagePath = nil
            }
            if let qty = action.fields?["quantity"]?.intValue { part.quantity = max(1, qty) }
            if let category = action.fields?["category"]?.stringValue, let c = PartCategory(rawValue: category) { part.category = c }
            if let status = action.fields?["status"]?.stringValue, let s = PartStatus(rawValue: status) { part.status = s }

            if let drone = try findDroneFromFields(action: action, modelContext: modelContext) {
                part.drone = drone
            }
            part.updatedAt = .now
            try partRepository.update(part)

        case "deletePart":
            guard let part = try findPart(action: action, modelContext: modelContext) else {
                throw NSError(domain: "AIActionExecutor", code: 4, userInfo: [NSLocalizedDescriptionKey: "Part not found"])
            }
            try partRepository.delete(part)

        default:
            throw NSError(domain: "AIActionExecutor", code: 999, userInfo: [NSLocalizedDescriptionKey: "Unsupported action type: \(action.type)"])
        }
    }

    private static func findDrone(action: AIAction, modelContext: ModelContext) throws -> Drone? {
        if let idString = action.targetId, let id = UUID(uuidString: idString) {
            var descriptor = FetchDescriptor<Drone>(predicate: #Predicate<Drone> { $0.id == id })
            descriptor.fetchLimit = 1
            return try modelContext.fetch(descriptor).first
        }
        if let name = action.targetName?.trimmedNonEmpty {
            let lowered = name.lowercased()
            let all = (try? modelContext.fetch(FetchDescriptor<Drone>())) ?? []
            return all.first { $0.name.lowercased() == lowered }
        }
        return nil
    }

    private static func findDroneFromFields(action: AIAction, modelContext: ModelContext) throws -> Drone? {
        if let idString = action.fields?["droneId"]?.stringValue, let id = UUID(uuidString: idString) {
            var descriptor = FetchDescriptor<Drone>(predicate: #Predicate<Drone> { $0.id == id })
            descriptor.fetchLimit = 1
            return try modelContext.fetch(descriptor).first
        }
        if let name = action.fields?["droneName"]?.stringValue?.trimmedNonEmpty {
            let lowered = name.lowercased()
            let all = (try? modelContext.fetch(FetchDescriptor<Drone>())) ?? []
            return all.first { $0.name.lowercased() == lowered }
        }
        return nil
    }

    private static func findPart(action: AIAction, modelContext: ModelContext) throws -> DronePart? {
        if let idString = action.targetId, let id = UUID(uuidString: idString) {
            var descriptor = FetchDescriptor<DronePart>(predicate: #Predicate<DronePart> { $0.id == id })
            descriptor.fetchLimit = 1
            return try modelContext.fetch(descriptor).first
        }
        if let name = action.targetName?.trimmedNonEmpty {
            let lowered = name.lowercased()
            let all = (try? modelContext.fetch(FetchDescriptor<DronePart>())) ?? []
            return all.first { $0.name.lowercased() == lowered }
        }
        return nil
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}

