//
//  PartStatus.swift
//  VirtualUAVHanger
//
//  Lifecycle status of a drone component.
//

import Foundation

/// Status of a component: installed on a drone, spare, or grounded.
enum PartStatus: String, Codable, CaseIterable, Identifiable {
    case installed = "Installed"
    case spare = "Spare"
    case grounded = "Grounded"

    var id: String { rawValue }
}
