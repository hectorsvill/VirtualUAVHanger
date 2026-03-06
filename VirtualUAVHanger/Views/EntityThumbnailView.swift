//
//  EntityThumbnailView.swift
//  VirtualUAVHanger
//
//  Displays a small image from local path or URL for fleet/component rows and detail.
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct EntityThumbnailView: View {
    let localImagePath: String?
    let imageURL: String?
    var size: CGFloat = 44
    var cornerRadius: CGFloat = 8

    private var hasImage: Bool {
        (localImagePath != nil && !(localImagePath?.isEmpty ?? true))
            || (imageURL != nil && !(imageURL?.isEmpty ?? true))
    }

    var body: some View {
        Group {
            if let path = localImagePath, let url = ImageStorageService.fileURL(forRelativePath: path) {
                loadFromFile(url)
            } else if let urlString = imageURL, !urlString.isEmpty, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholder
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipped()
        .cornerRadius(cornerRadius)
    }

    private var placeholder: some View {
        Image(systemName: "photo")
            .font(.title2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func loadFromFile(_ url: URL) -> some View {
        #if os(iOS)
        if let data = try? Data(contentsOf: url), let ui = UIImage(data: data) {
            Image(uiImage: ui)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            placeholder
        }
        #else
        if let data = try? Data(contentsOf: url), let ns = NSImage(data: data) {
            Image(nsImage: ns)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            placeholder
        }
        #endif
    }
}
