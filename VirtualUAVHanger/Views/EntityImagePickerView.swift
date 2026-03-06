//
//  EntityImagePickerView.swift
//  VirtualUAVHanger
//
//  Add photo by camera, library, or image URL for fleet/component.
//

import PhotosUI
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct EntityImagePickerView: View {
    @Binding var localImagePath: String?
    @Binding var imageURL: String?
    var label: String = "Photo"

    @State private var selectedItem: PhotosPickerItem?
    @State private var urlInput = ""
    @State private var showCamera = false
    @State private var loadError: String?

    private var hasImage: Bool {
        localImagePath != nil || (imageURL != nil && !(imageURL?.isEmpty ?? true))
    }

    var body: some View {
        Section(label) {
            if hasImage {
                currentImagePreview
            }
            HStack(spacing: 12) {
                #if os(iOS)
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Library", systemImage: "photo.on.rectangle.angled")
                        .font(.subheadline)
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task { await loadFromPicker(newItem) }
                }

                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera.fill")
                            .font(.subheadline)
                    }
                }
                #else
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Choose Photo", systemImage: "photo.on.rectangle.angled")
                        .font(.subheadline)
                }
                .onChange(of: selectedItem) { _, newItem in
                    Task { await loadFromPicker(newItem) }
                }
                #endif
            }
            .padding(.vertical, 4)

            HStack {
                TextField("Or image URL", text: $urlInput)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    #endif
                Button("Use URL") {
                    applyURL()
                }
                .disabled(urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let err = loadError {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if hasImage {
                Button(role: .destructive) {
                    clearImage()
                } label: {
                    Label("Remove Photo", systemImage: "trash")
                }
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showCamera) {
            CameraImagePicker { data in
                if let data, let path = ImageStorageService.saveImageData(data) {
                    localImagePath = path
                    imageURL = nil
                    loadError = nil
                }
                showCamera = false
            } onCancel: {
                showCamera = false
            }
        }
        #endif
    }

    @ViewBuilder
    private var currentImagePreview: some View {
        Group {
            if let path = localImagePath, let url = ImageStorageService.fileURL(forRelativePath: path) {
                thumbnailView(url: url, fromFile: true)
            } else if let urlString = imageURL, !urlString.isEmpty, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    case .empty:
                        ProgressView()
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 120)
                .clipped()
                .cornerRadius(8)
            }
        }
    }

    @ViewBuilder
    private func thumbnailView(url: URL, fromFile: Bool) -> some View {
        Group {
            #if os(iOS)
            if let data = try? Data(contentsOf: url), let ui = UIImage(data: data) {
                Image(uiImage: ui)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
            #else
            if let data = try? Data(contentsOf: url), let ns = NSImage(data: data) {
                Image(nsImage: ns)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
            #endif
        }
        .frame(height: 120)
        .clipped()
        .cornerRadius(8)
    }

    private func loadFromPicker(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        loadError = nil
        do {
            if let data = try await item.loadTransferable(type: Data.self), !data.isEmpty {
                await MainActor.run {
                    if let path = ImageStorageService.saveImageData(data) {
                        localImagePath = path
                        imageURL = nil
                    }
                    selectedItem = nil
                }
            }
        } catch {
            await MainActor.run {
                loadError = "Could not load photo"
                selectedItem = nil
            }
        }
    }

    private func applyURL() {
        let raw = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty, URL(string: raw) != nil else {
            loadError = "Invalid URL"
            return
        }
        imageURL = raw
        localImagePath = nil
        loadError = nil
    }

    private func clearImage() {
        if let path = localImagePath {
            ImageStorageService.removeImage(atRelativePath: path)
        }
        localImagePath = nil
        imageURL = nil
        urlInput = ""
        selectedItem = nil
        loadError = nil
    }
}

// MARK: - Camera picker (iOS)

#if os(iOS)
import UIKit

struct CameraImagePicker: UIViewControllerRepresentable {
    var onCapture: (Data?) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraImagePicker
        init(_ parent: CameraImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            let data = image?.jpegData(compressionQuality: 0.85)
            parent.onCapture(data)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}
#endif
