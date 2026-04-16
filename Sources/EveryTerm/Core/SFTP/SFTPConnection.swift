import Foundation

/// SFTP operations protocol — abstracts Citadel SFTPClient for testability.
public protocol SFTPConnection: Actor {
    func listDirectory(_ path: String) async throws -> [SFTPFileEntry]
    func stat(_ path: String) async throws -> SFTPFileEntry
    func createDirectory(_ path: String) async throws
    func removeItem(at path: String, isDirectory: Bool) async throws
    func rename(from: String, to: String) async throws
    func download(remotePath: String, progress: (@Sendable (Int64, Int64) -> Void)?) async throws -> Data
    func upload(data: Data, to remotePath: String, progress: (@Sendable (Int64, Int64) -> Void)?) async throws
    func changePermissions(_ path: String, permissions: UInt32) async throws
}

/// Represents a remote file/directory entry from SFTP.
public struct SFTPFileEntry: Identifiable, Sendable {
    public let id: String          // full path
    public var name: String
    public var path: String
    public var size: Int64
    public var permissions: UInt32
    public var modifiedAt: Date
    public var ownerUid: UInt32
    public var ownerGid: UInt32
    public var isDirectory: Bool
    public var isSymlink: Bool
    public var symlinkTarget: String?

    public init(
        id: String,
        name: String,
        path: String,
        size: Int64,
        permissions: UInt32,
        modifiedAt: Date,
        ownerUid: UInt32,
        ownerGid: UInt32,
        isDirectory: Bool,
        isSymlink: Bool,
        symlinkTarget: String?
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.size = size
        self.permissions = permissions
        self.modifiedAt = modifiedAt
        self.ownerUid = ownerUid
        self.ownerGid = ownerGid
        self.isDirectory = isDirectory
        self.isSymlink = isSymlink
        self.symlinkTarget = symlinkTarget
    }

    /// Decode raw filename bytes with UTF-8, falling back to ISO-8859-1.
    public static func decodeFilename(_ bytes: [UInt8]) -> String {
        if let utf8 = String(bytes: bytes, encoding: .utf8) {
            return utf8
        }
        return String(bytes: bytes, encoding: .isoLatin1) ?? String(bytes: bytes, encoding: .ascii) ?? "?"
    }
}
