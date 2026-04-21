import Foundation

/// Persistent record of a remote host fingerprint trusted by the user.
///
/// The type is designed to be SwiftData-friendly (`@Model` in production). To
/// keep the current codebase dependency-free we ship it as a plain `Codable`
/// class — promoting to `@Model` is a one-line change once SwiftData is
/// adopted.
@MainActor
public final class KnownHost: Identifiable, @preconcurrency Codable {
    public nonisolated let id: UUID
    public nonisolated let host: String
    public nonisolated let port: Int
    /// Human-readable key type (e.g. "ssh-ed25519", "ssh-rsa").
    public var keyType: String
    /// Base64-encoded public key blob.
    public var publicKey: String
    /// Canonical fingerprint (e.g. SHA-256 Base64) for display + quick match.
    public var fingerprint: String
    public var firstSeenAt: Date
    public var lastSeenAt: Date

    public init(
        id: UUID = UUID(),
        host: String,
        port: Int,
        keyType: String,
        publicKey: String,
        fingerprint: String,
        firstSeenAt: Date = Date(),
        lastSeenAt: Date = Date()
    ) {
        self.id = id
        self.host = host
        self.port = port
        self.keyType = keyType
        self.publicKey = publicKey
        self.fingerprint = fingerprint
        self.firstSeenAt = firstSeenAt
        self.lastSeenAt = lastSeenAt
    }

    /// Compose a stable lookup key for a (host, port) pair.
    public static func lookupKey(host: String, port: Int) -> String {
        "\(host):\(port)"
    }

    public var lookupKey: String {
        Self.lookupKey(host: host, port: port)
    }
}
