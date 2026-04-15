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

        var collectedURLs: [URL] = []
        let group = DispatchGroup()

        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    return
                }
                collectedURLs.append(url)
            }
        }

        group.notify(queue: .main) {
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
