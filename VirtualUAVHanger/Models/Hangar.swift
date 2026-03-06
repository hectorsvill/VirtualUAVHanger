//
//  Hangar.swift
//  VirtualUAVHanger
//
//  SwiftData model: Location (Hangar) containing one or more drones (Fleet).
//

import Foundation
import SwiftData

/// A location (hangar) that contains one or more drones (fleet).
@Model
final class Hangar {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var imageURL: String?
    var localImagePath: String?

    @Relationship(inverse: \Drone.hangar)
    var drones: [Drone] = []

    init(
        id: UUID = UUID(),
        name: String,
        imageURL: String? = nil,
        localImagePath: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.localImagePath = localImagePath
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
