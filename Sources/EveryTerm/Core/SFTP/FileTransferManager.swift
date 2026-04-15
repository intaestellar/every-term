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

    public func enqueue(_ item: TransferItem) {
        transferQueue.append(item)
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
    public func uploadFolder(localPath: String, remotePath: String) async throws {
        let fm = FileManager.default
        guard fm.fileExists(atPath: localPath) else {
            throw FileTransferError.localPathNotFound(localPath)
        }

        try await connection.createDirectory(remotePath)

        let contents = try fm.contentsOfDirectory(atPath: localPath)
        for item in contents {
            let localItem = (localPath as NSString).appendingPathComponent(item)
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
