//
//  PartRepositoryEnvironmentKey.swift
//  VirtualUAVHanger
//
//  Injects PartRepository into the SwiftUI environment for MVVM use.
//

import SwiftData
import SwiftUI

private struct PartRepositoryKey: EnvironmentKey {
    static let defaultValue: PartRepositoryProtocol? = nil
}

extension EnvironmentValues {
    /// Use from a View that has access to `modelContext`; provide a PartRepository built with that context.
    var partRepository: PartRepositoryProtocol? {
        get { self[PartRepositoryKey.self] }
        set { self[PartRepositoryKey.self] = newValue }
    }
}

extension View {
    /// Injects PartRepository built from the view's ModelContext. Call on a view inside a `.modelContainer(...)` hierarchy.
    func withPartRepository(from modelContext: ModelContext) -> some View {
        environment(\.partRepository, PartRepository(modelContext: modelContext))
    }
}
