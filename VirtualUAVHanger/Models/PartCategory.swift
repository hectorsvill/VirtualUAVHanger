//
//  PartCategory.swift
//  VirtualUAVHanger
//
//  Component category for FPV/autonomous drone parts.
//

import Foundation

/// Category of a drone component (motor, ESC, flight controller, VTX).
enum PartCategory: String, Codable, CaseIterable, Identifiable {
    case motor = "Motor"
    case esc = "ESC"
    case fc = "FC"
    case vtx = "VTX"

    var id: String { rawValue }
}
