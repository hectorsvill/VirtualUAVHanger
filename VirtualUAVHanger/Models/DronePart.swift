//
//  DronePart.swift
//  VirtualUAVHanger
//
//  SwiftData model: A component (part) — many belong to one Drone.
//

import Foundation
import SwiftData

/// A drone component (part) with manual and status; many components belong to one Drone.
@Model
final class DronePart: Identifiable {
    var id: UUID
    var name: String
    var categoryRaw: String  // PartCategory.rawValue for SwiftData persistence
    var brand: String
    var serialNumber: String
    var quantity: Int
    var manualURL: String?
    var localManualPath: String?
    var imageURL: String?
    var localImagePath: String?
    var statusRaw: String    // PartStatus.rawValue for SwiftData persistence
    var createdAt: Date
    var updatedAt: Date

    var drone: Drone?

    var category: PartCategory {
        get { PartCategory(rawValue: categoryRaw) ?? .motor }
        set { categoryRaw = newValue.rawValue }
    }

    var status: PartStatus {
        get { PartStatus(rawValue: statusRaw) ?? .spare }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        category: PartCategory,
        brand: String,
        serialNumber: String = "",
        quantity: Int = 1,
        manualURL: String? = nil,
        localManualPath: String? = nil,
        imageURL: String? = nil,
        localImagePath: String? = nil,
        status: PartStatus = .spare,
        drone: Drone? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.brand = brand
        self.serialNumber = serialNumber
        self.quantity = quantity
        self.manualURL = manualURL
        self.localManualPath = localManualPath
        self.imageURL = imageURL
        self.localImagePath = localImagePath
        self.statusRaw = status.rawValue
        self.drone = drone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
