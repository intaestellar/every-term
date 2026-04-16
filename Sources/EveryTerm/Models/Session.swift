import Foundation

/// Session is a mutable reference type that must be accessed only from the MainActor.
/// All mutable properties are protected by @MainActor isolation.
/// `@unchecked Sendable` is used because all access is enforced to happen on MainActor
/// via SessionStore. Direct cross-actor access is prevented by the class not being `Sendable`.
@MainActor
public final class Session: Identifiable, @preconcurrency Codable, @unchecked Sendable {
    public nonisolated let id: UUID
    public var name: String
    public var type: SessionType
    public var host: String
    public var port: Int
    public var username: String
    public var authMethod: AuthMethod
    public var keyPath: String?
    public var jumpHostId: UUID?
    public var keepAliveInterval: Int
    public var encoding: String
    public var startupCommand: String?
    public var icon: String?
    public var colorHex: String?
    public var groupId: UUID?
    public nonisolated let createdAt: Date
    public var lastConnectedAt: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        type: SessionType,
        host: String,
        username: String,
        authMethod: AuthMethod,
        port: Int = 22,
        keyPath: String? = nil,
        jumpHostId: UUID? = nil,
        keepAliveInterval: Int = 60,
        encoding: String = "UTF-8",
        startupCommand: String? = nil,
        icon: String? = nil,
        colorHex: String? = nil,
        groupId: UUID? = nil,
        createdAt: Date = Date(),
        lastConnectedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.host = host
        self.port = port
        self.username = username
        self.authMethod = authMethod
        self.keyPath = keyPath
        self.jumpHostId = jumpHostId
        self.keepAliveInterval = keepAliveInterval
        self.encoding = encoding
        self.startupCommand = startupCommand
        self.icon = icon
        self.colorHex = colorHex
        self.groupId = groupId
        self.createdAt = createdAt
        self.lastConnectedAt = lastConnectedAt
    }
}

// MARK: - SessionChainValidator

public enum SessionChainError: Error {
    case circularReference(sessionId: UUID)
    case missingJumpHost(sessionId: UUID, jumpHostId: UUID)
}

@MainActor
public struct SessionChainValidator: Sendable {
    public init() {}

    public func validate(session: Session, allSessions: [Session]) throws {
        guard let jumpHostId = session.jumpHostId else {
            return // No jump host, valid
        }

        var visited = Set<UUID>()
        visited.insert(session.id)
        var currentJumpHostId: UUID? = jumpHostId

        while let nextId = currentJumpHostId {
            if visited.contains(nextId) {
                throw SessionChainError.circularReference(sessionId: nextId)
            }

            guard let jumpHost = allSessions.first(where: { $0.id == nextId }) else {
                throw SessionChainError.missingJumpHost(sessionId: session.id, jumpHostId: nextId)
            }

            visited.insert(nextId)
            currentJumpHostId = jumpHost.jumpHostId
        }
    }
}
