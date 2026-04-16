import Foundation
import Combine

// MARK: - SessionPersistence Protocol

/// Abstraction for session persistence. Implementations can use SwiftData, JSON files, or in-memory storage.
@MainActor
public protocol SessionPersistence: Sendable {
    func loadSessions() throws -> [Session]
    func saveSessions(_ sessions: [Session]) throws
    func loadGroups() throws -> [SessionGroup]
    func saveGroups(_ groups: [SessionGroup]) throws
}

/// In-memory persistence for testing and initial development.
/// SwiftData-based persistence will replace this in SP-2.
@MainActor
public final class InMemorySessionPersistence: SessionPersistence {
    public init() {}
    public func loadSessions() throws -> [Session] { [] }
    public func saveSessions(_ sessions: [Session]) throws {}
    public func loadGroups() throws -> [SessionGroup] { [] }
    public func saveGroups(_ groups: [SessionGroup]) throws {}
}

@MainActor
public final class SessionStore: ObservableObject {
    @Published public private(set) var sessionsDidChange: Int = 0
    private var sessions: [Session] = []
    private var groups: [SessionGroup] = []
    // Protocol-specific configs keyed by owning `Session.id`. Persistence
    // for these SwiftData models is deferred to the container in SP-5;
    // keeping them in memory is sufficient for the editor round-trip.
    private var rdpConfigs: [UUID: RDPSessionConfig] = [:]
    private var vncConfigs: [UUID: VNCSessionConfig] = [:]
    private var serialConfigs: [UUID: SerialSessionConfig] = [:]
    private let persistence: any SessionPersistence

    public init(persistence: any SessionPersistence = InMemorySessionPersistence()) {
        self.persistence = persistence
        // Load persisted sessions on init
        if let loaded = try? persistence.loadSessions() {
            self.sessions = loaded
        }
        if let loaded = try? persistence.loadGroups() {
            self.groups = loaded
        }
    }

    public static func forTesting() -> SessionStore {
        SessionStore(persistence: InMemorySessionPersistence())
    }

    // MARK: - Session CRUD

    public var allSessions: [Session] {
        sessions
    }

    public func add(_ session: Session) throws {
        sessions.append(session)
        sessionsDidChange += 1
    }

    public func session(byId id: UUID) -> Session? {
        sessions.first(where: { $0.id == id })
    }

    public func update(_ id: UUID, name: String? = nil, host: String? = nil) throws {
        guard let session = sessions.first(where: { $0.id == id }) else {
            throw SessionStoreError.sessionNotFound(id)
        }
        if let name = name { session.name = name }
        if let host = host { session.host = host }
        sessionsDidChange += 1
    }

    public func delete(_ id: UUID) throws {
        sessions.removeAll(where: { $0.id == id })
        rdpConfigs.removeValue(forKey: id)
        vncConfigs.removeValue(forKey: id)
        serialConfigs.removeValue(forKey: id)
        sessionsDidChange += 1
    }

    // MARK: - Protocol-specific configs

    public func setRDPConfig(_ config: RDPSessionConfig, forSessionId id: UUID) {
        rdpConfigs[id] = config
    }

    public func rdpConfig(forSessionId id: UUID) -> RDPSessionConfig? {
        rdpConfigs[id]
    }

    public func setVNCConfig(_ config: VNCSessionConfig, forSessionId id: UUID) {
        vncConfigs[id] = config
    }

    public func vncConfig(forSessionId id: UUID) -> VNCSessionConfig? {
        vncConfigs[id]
    }

    public func setSerialConfig(_ config: SerialSessionConfig, forSessionId id: UUID) {
        serialConfigs[id] = config
    }

    public func serialConfig(forSessionId id: UUID) -> SerialSessionConfig? {
        serialConfigs[id]
    }

    // MARK: - Group CRUD

    public var allGroups: [SessionGroup] {
        groups
    }

    public func addGroup(_ group: SessionGroup) throws {
        groups.append(group)
    }

    public func group(byId id: UUID) -> SessionGroup? {
        groups.first(where: { $0.id == id })
    }

    public func updateGroup(_ id: UUID, name: String? = nil) throws {
        guard let group = groups.first(where: { $0.id == id }) else {
            throw SessionStoreError.groupNotFound(id)
        }
        if let name = name { group.name = name }
    }

    public func deleteGroup(_ id: UUID) throws {
        groups.removeAll(where: { $0.id == id })
    }

    public func assignToGroup(sessionId: UUID, groupId: UUID) throws {
        guard let session = sessions.first(where: { $0.id == sessionId }) else {
            throw SessionStoreError.sessionNotFound(sessionId)
        }
        session.groupId = groupId
    }

    public func sessions(inGroup groupId: UUID) -> [Session] {
        sessions.filter { $0.groupId == groupId }
    }

    // MARK: - SSH Config Parsing

    public func parseSSHConfig(_ content: String) throws -> [Session] {
        var parsedSessions: [Session] = []
        var currentHost: String?
        var currentProps: [String: String] = [:]

        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            let parts = trimmed.split(separator: " ", maxSplits: 1)
            guard parts.count >= 2 else { continue }

            let key = String(parts[0])
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)

            if key.lowercased() == "host" {
                // Save previous host block
                if let host = currentHost {
                    if let session = buildSession(name: host, props: currentProps, allParsed: parsedSessions) {
                        parsedSessions.append(session)
                    }
                }

                // Skip wildcard hosts
                if value.contains("*") {
                    currentHost = nil
                    currentProps = [:]
                } else {
                    currentHost = value
                    currentProps = [:]
                }
            } else if currentHost != nil {
                currentProps[key.lowercased()] = value
            }
        }

        // Save last host block
        if let host = currentHost {
            if let session = buildSession(name: host, props: currentProps, allParsed: parsedSessions) {
                parsedSessions.append(session)
            }
        }

        return parsedSessions
    }

    private func buildSession(name: String, props: [String: String], allParsed: [Session]) -> Session? {
        let hostName = props["hostname"] ?? name
        let username = props["user"] ?? "root"
        let port = Int(props["port"] ?? "22") ?? 22
        let keyPath = props["identityfile"]

        var jumpHostId: UUID?
        if let proxyJump = props["proxyjump"] {
            // Look up the proxy jump host in already parsed sessions
            if let jumpSession = allParsed.first(where: { $0.name == proxyJump }) {
                jumpHostId = jumpSession.id
            }
        }

        let authMethod: AuthMethod = keyPath != nil ? .key : .password

        return Session(
            name: name,
            type: .ssh,
            host: hostName,
            username: username,
            authMethod: authMethod,
            port: port,
            keyPath: keyPath,
            jumpHostId: jumpHostId
        )
    }

    // MARK: - JSON Export/Import

    public func exportToJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(sessions)
    }

    public func importFromJSON(_ data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let imported = try decoder.decode([Session].self, from: data)
        sessions.append(contentsOf: imported)
    }
}

public enum SessionStoreError: Error {
    case sessionNotFound(UUID)
    case groupNotFound(UUID)
}
