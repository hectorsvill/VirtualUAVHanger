//
//  Drone.swift
//  VirtualUAVHanger
//
//  SwiftData model: A drone (Fleet unit) belonging to a Hangar, with many components.
//

import Foundation
import SwiftData

/// A drone in the fleet; belongs to one Hangar and has many components (DronePart).
@Model
final class Drone {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var imageURL: String?
    var localImagePath: String?

    var hangar: Hangar?

    @Relationship(inverse: \DronePart.drone)
    var parts: [DronePart] = []

    init(
        id: UUID = UUID(),
        name: String,
        hangar: Hangar? = nil,
        imageURL: String? = nil,
        localImagePath: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.hangar = hangar
        self.imageURL = imageURL
        self.localImagePath = localImagePath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
