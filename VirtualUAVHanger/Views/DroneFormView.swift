//
//  DroneFormView.swift
//  VirtualUAVHanger
//
//  Add drone (single global hangar): name and optional photo (camera, library, or URL).
//

import SwiftUI

struct DroneFormView: View {
    var onSave: (String, String?, String?) -> Void
    var onCancel: () -> Void
    @State private var name = ""
    @State private var imageURL: String?
    @State private var localImagePath: String?
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                TextField("Drone name", text: $name)
                    .focused($nameFocused)
                EntityImagePickerView(
                    localImagePath: $localImagePath,
                    imageURL: $imageURL,
                    label: "Photo"
                )
            }
            .navigationTitle("New Drone")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), imageURL, localImagePath)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { nameFocused = true }
        }
    }
}
