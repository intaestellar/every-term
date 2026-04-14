import Foundation

/// Session is intentionally NOT Sendable — it is a mutable reference type
/// and must be accessed only from the MainActor (enforced by SessionStore).
@MainActor
public final class Session: Identifiable, Codable, Sendable {
    public nonisolated let id: UUID
    public nonisolated(unsafe) var name: String
    public nonisolated(unsafe) var type: SessionType
    public nonisolated(unsafe) var host: String
    public nonisolated(unsafe) var port: Int
    public nonisolated(unsafe) var username: String
    public nonisolated(unsafe) var authMethod: AuthMethod
    public nonisolated(unsafe) var keyPath: String?
    public nonisolated(unsafe) var jumpHostId: UUID?
    public nonisolated(unsafe) var keepAliveInterval: Int
    public nonisolated(unsafe) var encoding: String
    public nonisolated(unsafe) var startupCommand: String?
    public nonisolated(unsafe) var icon: String?
    public nonisolated(unsafe) var colorHex: String?
    public nonisolated(unsafe) var groupId: UUID?
    public nonisolated let createdAt: Date
    public nonisolated(unsafe) var lastConnectedAt: Date?

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
