import Foundation

/// Direction of a file transfer.
public enum TransferDirection: Sendable {
    case upload
    case download
}

/// State of a file transfer.
public enum TransferState: Sendable {
    case queued
    case transferring(progress: Double)
    case completed
    case failed(Error)
    case cancelled
}

/// Policy for handling existing files during transfer.
public enum OverwritePolicy: Sendable {
    case overwrite
    case skip
    case ask
}

/// Represents a single file transfer operation.
public struct TransferItem: Identifiable, Sendable {
    public let id: UUID
    public var sourcePath: String
    public var destinationPath: String
    public var direction: TransferDirection
    public var totalBytes: Int64
    public var transferredBytes: Int64
    public var state: TransferState
    public var speed: Double // bytes/sec (moving average)

    public init(
        id: UUID,
        sourcePath: String,
        destinationPath: String,
        direction: TransferDirection,
        totalBytes: Int64,
        transferredBytes: Int64,
        state: TransferState,
        speed: Double
    ) {
        self.id = id
        self.sourcePath = sourcePath
        self.destinationPath = destinationPath
        self.direction = direction
        self.totalBytes = totalBytes
        self.transferredBytes = transferredBytes
        self.state = state
        self.speed = speed
    }
}

/// Manages file transfer queue with concurrency limits.
public actor FileTransferManager {
    private let connection: any SFTPConnection
    public private(set) var transferQueue: [TransferItem] = []
    public let maxConcurrentTransfers: Int = 3

    public init(connection: any SFTPConnection) {
        self.connection = connection
    }

    private var activeTransferCount: Int = 0

    public func enqueue(_ item: TransferItem) {
        transferQueue.append(item)
        Task { await processQueue() }
    }

    /// Dequeue pending items and start actual transfers up to maxConcurrentTransfers.
    private func processQueue() async {
        while activeTransferCount < maxConcurrentTransfers {
            guard let index = transferQueue.firstIndex(where: {
                if case .queued = $0.state { return true }
                return false
            }) else { break }

            let item = transferQueue[index]
            transferQueue[index].state = .transferring(progress: 0)
            activeTransferCount += 1

            let itemId = item.id
            Task {
                await startTransfer(item)
                activeTransferCount -= 1
                // Trigger next queued item
                await processQueue()
                _ = itemId // suppress unused warning
            }
        }
    }

    /// Execute a single transfer item.
    private func startTransfer(_ item: TransferItem) async {
        guard let index = transferQueue.firstIndex(where: { $0.id == item.id }) else { return }

        do {
            switch item.direction {
            case .upload:
                let data = try Data(contentsOf: URL(fileURLWithPath: item.sourcePath))
                try await connection.upload(data: data, to: item.destinationPath) { sent, total in
                    Task { await self.updateProgress(id: item.id, sent: sent, total: total) }
                }
            case .download:
                let data = try await connection.download(remotePath: item.sourcePath) { sent, total in
                    Task { await self.updateProgress(id: item.id, sent: sent, total: total) }
                }
                try data.write(to: URL(fileURLWithPath: item.destinationPath))
            }

            if let idx = transferQueue.firstIndex(where: { $0.id == item.id }) {
                transferQueue[idx].state = .completed
            }
        } catch {
            if let idx = transferQueue.firstIndex(where: { $0.id == item.id }) {
                // Only mark as failed if not already cancelled
                if case .cancelled = transferQueue[idx].state { return }
                transferQueue[idx].state = .failed(error)
            }
        }
        _ = index // suppress unused warning
    }

    private func updateProgress(id: UUID, sent: Int64, total: Int64) {
        guard let idx = transferQueue.firstIndex(where: { $0.id == id }) else { return }
        let progress = total > 0 ? Double(sent) / Double(total) : 0
        transferQueue[idx].state = .transferring(progress: progress)
        transferQueue[idx].transferredBytes = sent
    }

    public func cancel(_ id: UUID) {
        if let index = transferQueue.firstIndex(where: { $0.id == id }) {
            transferQueue[index].state = .cancelled
        }
    }

    public func pause(_ id: UUID) {
        // Mark as queued (paused) — actual pause implementation requires chunked transfer
        if let index = transferQueue.firstIndex(where: { $0.id == id }) {
            transferQueue[index].state = .queued
        }
    }

    public func resume(_ id: UUID) {
        // Resume by re-queueing
        if let index = transferQueue.firstIndex(where: { $0.id == id }) {
            transferQueue[index].state = .queued
        }
    }

    /// Delete a remote file or directory based on isDirectory flag.
    public func deleteItem(_ entry: SFTPFileEntry) async throws {
        try await connection.removeItem(at: entry.path, isDirectory: entry.isDirectory)
    }

    /// Recursively upload a local folder to a remote path.
    /// Skips symbolic links to prevent infinite recursion from circular symlinks.
    public func uploadFolder(localPath: String, remotePath: String) async throws {
        let fm = FileManager.default
        guard fm.fileExists(atPath: localPath) else {
            throw FileTransferError.localPathNotFound(localPath)
        }

        try await connection.createDirectory(remotePath)

        let localURL = URL(fileURLWithPath: localPath)
        let contents = try fm.contentsOfDirectory(
            at: localURL,
            includingPropertiesForKeys: [.isSymbolicLinkKey],
            options: [.skipsHiddenFiles]
        )
        for itemURL in contents {
            let resourceValues = try itemURL.resourceValues(forKeys: [.isSymbolicLinkKey])
            if resourceValues.isSymbolicLink == true { continue }

            let item = itemURL.lastPathComponent
            let localItem = itemURL.path
            let remoteItem = remotePath.hasSuffix("/") ? "\(remotePath)\(item)" : "\(remotePath)/\(item)"

            var isDir: ObjCBool = false
            fm.fileExists(atPath: localItem, isDirectory: &isDir)

            if isDir.boolValue {
                try await uploadFolder(localPath: localItem, remotePath: remoteItem)
            } else {
                let data = try Data(contentsOf: URL(fileURLWithPath: localItem))
                try await connection.upload(data: data, to: remoteItem, progress: nil)
            }
        }
    }

    /// Recursively download a remote folder to a local path.
    public func downloadFolder(remotePath: String, localPath: String) async throws {
        let fm = FileManager.default
        try fm.createDirectory(atPath: localPath, withIntermediateDirectories: true)

        let entries = try await connection.listDirectory(remotePath)
        for entry in entries {
            let localItem = (localPath as NSString).appendingPathComponent(entry.name)

            if entry.isDirectory {
                try await downloadFolder(remotePath: entry.path, localPath: localItem)
            } else {
                let data = try await connection.download(remotePath: entry.path, progress: nil)
                try data.write(to: URL(fileURLWithPath: localItem))
            }
        }
    }
}

enum FileTransferError: Error {
    case localPathNotFound(String)
}
