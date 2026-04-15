import Foundation
@preconcurrency import Citadel
@preconcurrency import NIO

/// Citadel-based SFTP adapter that wraps SSHAdapter for SFTP operations.
public actor CitadelSFTPAdapter: SFTPConnection {
    private let sshAdapter: SSHAdapter

    public init(sshAdapter: SSHAdapter) {
        self.sshAdapter = sshAdapter
    }

    public func listDirectory(_ path: String) async throws -> [SFTPFileEntry] {
        let sftpClient = try await sshAdapter.openSFTPClient()
        let nameMessages = try await sftpClient.listDirectory(atPath: path)

        var entries: [SFTPFileEntry] = []
        for nameMsg in nameMessages {
            for component in nameMsg.components {
                let name = component.filename
                guard name != "." && name != ".." else { continue }

                let perms = component.attributes.permissions ?? 0
                let size = Int64(component.attributes.size ?? 0)
                let isDir = (perms & 0o170000) == 0o040000
                let isSym = (perms & 0o170000) == 0o120000

                let modTime: Date = component.attributes.accessModificationTime?.modificationTime ?? Date.distantPast

                let uid = component.attributes.uidgid?.userId ?? 0
                let gid = component.attributes.uidgid?.groupId ?? 0

                let fullPath = path.hasSuffix("/") ? "\(path)\(name)" : "\(path)/\(name)"

                entries.append(SFTPFileEntry(
                    id: fullPath,
                    name: name,
                    path: fullPath,
                    size: size,
                    permissions: perms,
                    modifiedAt: modTime,
                    ownerUid: uid,
                    ownerGid: gid,
                    isDirectory: isDir,
                    isSymlink: isSym,
                    symlinkTarget: nil
                ))
            }
        }
        return entries
    }

    public func stat(_ path: String) async throws -> SFTPFileEntry {
        let sftpClient = try await sshAdapter.openSFTPClient()
        let attrs = try await sftpClient.getAttributes(at: path)
        let name = (path as NSString).lastPathComponent
        let perms = attrs.permissions ?? 0
        let size = Int64(attrs.size ?? 0)
        let isDir = (perms & 0o170000) == 0o040000
        let isSym = (perms & 0o170000) == 0o120000

        let modTime: Date = attrs.accessModificationTime?.modificationTime ?? Date.distantPast

        let uid = attrs.uidgid?.userId ?? 0
        let gid = attrs.uidgid?.groupId ?? 0

        return SFTPFileEntry(
            id: path,
            name: name,
            path: path,
            size: size,
            permissions: perms,
            modifiedAt: modTime,
            ownerUid: uid,
            ownerGid: gid,
            isDirectory: isDir,
            isSymlink: isSym,
            symlinkTarget: nil
        )
    }

    public func createDirectory(_ path: String) async throws {
        let sftpClient = try await sshAdapter.openSFTPClient()
        try await sftpClient.createDirectory(atPath: path)
    }

    public func removeItem(at path: String, isDirectory: Bool) async throws {
        let sftpClient = try await sshAdapter.openSFTPClient()
        if isDirectory {
            try await sftpClient.rmdir(at: path)
        } else {
            try await sftpClient.remove(at: path)
        }
    }

    public func rename(from: String, to: String) async throws {
        let sftpClient = try await sshAdapter.openSFTPClient()
        try await sftpClient.rename(at: from, to: to)
    }

    public func download(remotePath: String, progress: (@Sendable (Int64, Int64) -> Void)?) async throws -> Data {
        let sftpClient = try await sshAdapter.openSFTPClient()
        let file = try await sftpClient.openFile(filePath: remotePath, flags: .read)
        let buffer = try await file.readAll()
        let data = Data(buffer.readableBytesView)
        progress?(Int64(data.count), Int64(data.count))
        try await file.close()
        return data
    }

    public func upload(data: Data, to remotePath: String, progress: (@Sendable (Int64, Int64) -> Void)?) async throws {
        let sftpClient = try await sshAdapter.openSFTPClient()
        let file = try await sftpClient.openFile(filePath: remotePath, flags: [.write, .create, .truncate])
        let buffer = ByteBuffer(data: data)
        try await file.write(buffer)
        progress?(Int64(data.count), Int64(data.count))
        try await file.close()
    }

    public func changePermissions(_ path: String, permissions: UInt32) async throws {
        let sftpClient = try await sshAdapter.openSFTPClient()
        var attrs = SFTPFileAttributes()
        attrs.permissions = permissions
        try await sftpClient.setAttributes(at: path, to: attrs)
    }
}
