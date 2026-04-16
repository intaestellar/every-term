import SwiftUI
import UniformTypeIdentifiers

/// Drop delegate for uploading local files to SFTP via drag and drop.
public struct SFTPDropDelegate: DropDelegate {
    public let currentPath: String
    public let onUpload: @MainActor ([URL]) -> Void

    public init(currentPath: String, onUpload: @escaping @MainActor ([URL]) -> Void) {
        self.currentPath = currentPath
        self.onUpload = onUpload
    }

    public func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [.fileURL])
    }

    public func performDrop(info: DropInfo) -> Bool {
        let providers = info.itemProviders(for: [.fileURL])
        guard !providers.isEmpty else { return false }

        Task { @MainActor in
            var collectedURLs: [URL] = []
            for provider in providers {
                if let url = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) as? Data {
                    if let fileURL = URL(dataRepresentation: url, relativeTo: nil) {
                        collectedURLs.append(fileURL)
                    }
                }
            }
            if !collectedURLs.isEmpty {
                onUpload(collectedURLs)
            }
        }

        return true
    }

    public func dropEntered(info: DropInfo) {
        // Visual feedback handled by SwiftUI overlay
    }

    public func dropExited(info: DropInfo) {
        // Visual feedback handled by SwiftUI overlay
    }
}
