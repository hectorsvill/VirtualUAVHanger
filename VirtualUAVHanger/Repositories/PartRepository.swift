//
//  PartRepository.swift
//  VirtualUAVHanger
//
//  SwiftData-backed implementation of PartRepositoryProtocol (CRUD for DronePart).
//

import Foundation
import SwiftData

/// SwiftData implementation of part persistence. Use this for local-first; swap for a remote implementation later.
final class PartRepository: PartRepositoryProtocol, @unchecked Sendable {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func create(_ part: DronePart) throws {
        modelContext.insert(part)
        try modelContext.save()
    }

    func fetchAll() throws -> [DronePart] {
        let descriptor = FetchDescriptor<DronePart>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetch(byId id: UUID) throws -> DronePart? {
        var descriptor = FetchDescriptor<DronePart>(
            predicate: #Predicate<DronePart> { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func fetch(byDrone drone: Drone) throws -> [DronePart] {
        let parts = drone.parts.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        return parts
    }

    func fetch(byCategory category: PartCategory) throws -> [DronePart] {
        let raw = category.rawValue
        var descriptor = FetchDescriptor<DronePart>(
            predicate: #Predicate<DronePart> { $0.categoryRaw == raw },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetch(byStatus status: PartStatus) throws -> [DronePart] {
        let raw = status.rawValue
        var descriptor = FetchDescriptor<DronePart>(
            predicate: #Predicate<DronePart> { $0.statusRaw == raw },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func update(_ part: DronePart) throws {
        part.updatedAt = .now
        try modelContext.save()
    }

    func delete(_ part: DronePart) throws {
        modelContext.delete(part)
        try modelContext.save()
    }

    func save() throws {
        try modelContext.save()
    }
}
