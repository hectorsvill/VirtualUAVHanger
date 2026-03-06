//
//  PartRepositoryProtocol.swift
//  VirtualUAVHanger
//
//  Abstract interface for part storage; allows swapping SwiftData for a Go backend or n8n.
//

import Foundation
import SwiftData

/// Protocol for component (DronePart) persistence. Implement with SwiftData now; replace with remote API later.
protocol PartRepositoryProtocol: Sendable {
    func create(_ part: DronePart) throws
    func fetchAll() throws -> [DronePart]
    func fetch(byId id: UUID) throws -> DronePart?
    func fetch(byDrone drone: Drone) throws -> [DronePart]
    func fetch(byCategory category: PartCategory) throws -> [DronePart]
    func fetch(byStatus status: PartStatus) throws -> [DronePart]
    func update(_ part: DronePart) throws
    func delete(_ part: DronePart) throws
    func save() throws
}
