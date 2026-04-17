import Foundation

/// Outcome of evaluating a remote host key against the local known-hosts
/// store.
public enum HostKeyDecision: Sendable, Equatable {
    /// First time this host is seen — TOFU (trust on first use) records the
    /// key and allows the connection.
    case trustOnFirstUse
    /// The presented key matches the pinned fingerprint.
    case trusted
    /// The pinned fingerprint differs from what the server presented.
    /// Potential MITM — the caller MUST surface a blocking UI prompt.
    case mismatch(expected: String, actual: String)
}

/// In-memory storage abstraction for known hosts. Production wires this to a
/// SwiftData / JSON file backed implementation; tests use the in-memory one.
@MainActor
public protocol KnownHostStore: AnyObject {
    func find(host: String, port: Int) -> KnownHost?
    func upsert(_ host: KnownHost)
    func remove(host: String, port: Int)
    var all: [KnownHost] { get }
}

/// Simple in-memory `KnownHostStore` used by unit tests and as a placeholder
/// until the SwiftData container is wired up.
@MainActor
public final class InMemoryKnownHostStore: KnownHostStore {
    private var store: [String: KnownHost] = [:]

    public init(seed: [KnownHost] = []) {
        for host in seed { upsert(host) }
    }

    public func find(host: String, port: Int) -> KnownHost? {
        store[KnownHost.lookupKey(host: host, port: port)]
    }

    public func upsert(_ host: KnownHost) {
        store[host.lookupKey] = host
    }

    public func remove(host: String, port: Int) {
        store.removeValue(forKey: KnownHost.lookupKey(host: host, port: port))
    }

    public var all: [KnownHost] {
        Array(store.values)
    }
}

/// TOFU (trust-on-first-use) style host key validator. Records unknown hosts
/// on first contact; flags fingerprint mismatches as `.mismatch`.
///
/// This is the model-level policy. Wiring the decision into the Citadel
/// `SSHHostKeyValidator` callback is the responsibility of `SSHAdapter`.
///
/// - Important: **Step 4-2 미완** — 이 타입과 ``KnownHost``,
///   ``InMemoryKnownHostStore`` 는 아직 `SSHAdapter.connect()` 에 배선되지
///   않았습니다. Citadel `SSHHostKeyValidator.custom(...)` 콜백 안에서
///   `evaluate(...)` 를 호출하는 어댑터 코드가 필요합니다.
///
/// - Note: `evaluate` uses `Date()` directly for `lastSeenAt`. When this
///   type is wired into production (Step 4-2), inject a `DateProvider`
///   (or `@dependency(\.date)`) so timestamps are testable.
@MainActor
public struct HostKeyValidator: Sendable {
    public let store: any KnownHostStore

    public init(store: any KnownHostStore) {
        self.store = store
    }

    /// Evaluate the presented key.
    ///
    /// - Parameters:
    ///   - host: Remote host name as entered by the user.
    ///   - port: Remote port.
    ///   - keyType: Algorithm identifier (e.g. "ssh-ed25519").
    ///   - publicKey: Base64 encoded public key blob.
    ///   - fingerprint: Canonical fingerprint (SHA-256 Base64).
    /// - Returns: A `HostKeyDecision` the caller must act on.
    public func evaluate(
        host: String,
        port: Int,
        keyType: String,
        publicKey: String,
        fingerprint: String
    ) -> HostKeyDecision {
        if let existing = store.find(host: host, port: port) {
            if existing.fingerprint == fingerprint {
                existing.lastSeenAt = Date()
                store.upsert(existing)
                return .trusted
            }
            return .mismatch(expected: existing.fingerprint, actual: fingerprint)
        }
        // TOFU — record and trust.
        let record = KnownHost(
            host: host,
            port: port,
            keyType: keyType,
            publicKey: publicKey,
            fingerprint: fingerprint
        )
        store.upsert(record)
        return .trustOnFirstUse
    }
}
