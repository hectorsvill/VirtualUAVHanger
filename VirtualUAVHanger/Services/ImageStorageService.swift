//
//  ImageStorageService.swift
//  VirtualUAVHanger
//
//  Saves and loads entity images under Documents/EntityImages.
//

import Foundation

enum ImageStorageService {
    private static let subdirectory = "EntityImages"

    static var imagesDirectoryURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appending(path: subdirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Saves image data to disk; returns a relative path suitable for storing in the model.
    static func saveImageData(_ data: Data, filename: String = UUID().uuidString) -> String? {
        let ext = (filename as NSString).pathExtension
        let name = ext.isEmpty ? "\(filename).jpg" : filename
        let fileURL = imagesDirectoryURL.appending(path: name)
        do {
            try data.write(to: fileURL)
            return name
        } catch {
            return nil
        }
    }

    /// Returns full file URL for a stored relative path, or nil if file doesn't exist.
    static func fileURL(forRelativePath path: String) -> URL? {
        let url = imagesDirectoryURL.appending(path: path)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Downloads image from URL, saves to disk, returns relative path. Call from background if needed.
    static func downloadAndSave(from urlString: String) async -> String? {
        guard let url = URL(string: urlString), url.scheme?.lowercased().hasPrefix("http") == true else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard !data.isEmpty else { return nil }
            return saveImageData(data, filename: "\(UUID().uuidString).jpg")
        } catch {
            return nil
        }
    }

    /// Removes stored image at relative path. Call when replacing or deleting entity image.
    static func removeImage(atRelativePath path: String) {
        guard let url = fileURL(forRelativePath: path) else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
