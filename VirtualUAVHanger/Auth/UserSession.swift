//
//  UserSession.swift
//  VirtualUAVHanger
//
//  Represents a signed-in user, persisted across launches.
//

import Foundation

// MARK: - Auth Provider

enum AuthProvider: String, Codable, Sendable, CaseIterable {
    case apple
    case google
    case email
    case guest

    var displayName: String {
        switch self {
        case .apple:  "Apple"
        case .google: "Google"
        case .email:  "Email"
        case .guest:  "Guest"
        }
    }

    /// `true` for any provider that represents a real, persistent account.
    var isRealAccount: Bool { self != .guest }
}

// MARK: - User Session

struct UserSession: Codable, Sendable, Identifiable, Equatable {
    let id: String
    let name: String?
    let email: String?
    let provider: AuthProvider

    /// Best available display name, falling back through name → email prefix → provider label.
    var displayName: String {
        if let name, !name.isEmpty { return name }
        if let email { return String(email.split(separator: "@").first ?? "Pilot") }
        return provider == .guest ? "Guest" : "Pilot"
    }

    /// Up-to-two letter initials for avatar placeholder.
    var initials: String {
        if provider == .guest { return "G" }
        if let name, !name.isEmpty {
            let words = name.split(separator: " ")
            switch words.count {
            case 1:  return String(words[0].prefix(1)).uppercased()
            default: return (String(words[0].prefix(1)) + String(words[1].prefix(1))).uppercased()
            }
        }
        return email.map { String($0.prefix(1)).uppercased() } ?? "?"
    }
}
