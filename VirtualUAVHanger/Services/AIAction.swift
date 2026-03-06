//
//  AIAction.swift
//  VirtualUAVHanger
//
//  Codable action format produced by the AI assistant for safe edits.
//

import Foundation

struct AIActionEnvelope: Codable {
    var actions: [AIAction]
}

struct AIAction: Codable {
    /// createDrone | updateDrone | deleteDrone | createPart | updatePart | deletePart
    var type: String
    /// Optional UUID (as string) for the target entity.
    var targetId: String?
    /// Optional name when no id exists (less reliable).
    var targetName: String?
    /// Fields to apply for creates/updates.
    var fields: [String: AIActionValue]?
}

enum AIActionValue: Codable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null; return }
        if let i = try? container.decode(Int.self) { self = .int(i); return }
        if let b = try? container.decode(Bool.self) { self = .bool(b); return }
        if let s = try? container.decode(String.self) { self = .string(s); return }
        self = .null
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        case .bool(let b): try container.encode(b)
        case .null: try container.encodeNil()
        }
    }

    var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }
    var intValue: Int? {
        if case .int(let i) = self { return i }
        return nil
    }
}

