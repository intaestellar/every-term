import Testing
import Foundation
@testable import EveryTerm

@Suite("HostKeyValidator Tests")
struct HostKeyValidatorTests {

    // MARK: - TOFU (Trust On First Use)

    @Test("Unknown host → trustOnFirstUse and stores the record")
    @MainActor func tofuForNewHost() {
        let store = InMemoryKnownHostStore()
        let validator = HostKeyValidator(store: store)

        let decision = validator.evaluate(
            host: "example.com",
            port: 22,
            keyType: "ssh-ed25519",
            publicKey: "AAAA",
            fingerprint: "SHA256:abc123"
        )

        #expect(decision == .trustOnFirstUse)
        #expect(store.all.count == 1)
        let record = store.find(host: "example.com", port: 22)
        #expect(record?.fingerprint == "SHA256:abc123")
        #expect(record?.keyType == "ssh-ed25519")
        #expect(record?.publicKey == "AAAA")
    }

    // MARK: - Trusted (fingerprint matches)

    @Test("Known host with matching fingerprint → trusted")
    @MainActor func trustedWhenFingerprintMatches() {
        let existing = KnownHost(
            host: "example.com",
            port: 22,
            keyType: "ssh-ed25519",
            publicKey: "AAAA",
            fingerprint: "SHA256:abc123"
        )
        let store = InMemoryKnownHostStore(seed: [existing])
        let validator = HostKeyValidator(store: store)

        let decision = validator.evaluate(
            host: "example.com",
            port: 22,
            keyType: "ssh-ed25519",
            publicKey: "AAAA",
            fingerprint: "SHA256:abc123"
        )

        #expect(decision == .trusted)
    }

    // MARK: - Mismatch

    @Test("Known host with different fingerprint → mismatch")
    @MainActor func mismatchWhenFingerprintDiffers() {
        let existing = KnownHost(
            host: "example.com",
            port: 22,
            keyType: "ssh-ed25519",
            publicKey: "AAAA",
            fingerprint: "SHA256:abc123"
        )
        let store = InMemoryKnownHostStore(seed: [existing])
        let validator = HostKeyValidator(store: store)

        let decision = validator.evaluate(
            host: "example.com",
            port: 22,
            keyType: "ssh-ed25519",
            publicKey: "BBBB",
            fingerprint: "SHA256:xyz789"
        )

        #expect(decision == .mismatch(expected: "SHA256:abc123", actual: "SHA256:xyz789"))
    }

    // MARK: - Port differentiation

    @Test("Same host different port → treated as separate host (TOFU)")
    @MainActor func differentPortIsSeparateHost() {
        let existing = KnownHost(
            host: "example.com",
            port: 22,
            keyType: "ssh-ed25519",
            publicKey: "AAAA",
            fingerprint: "SHA256:abc123"
        )
        let store = InMemoryKnownHostStore(seed: [existing])
        let validator = HostKeyValidator(store: store)

        let decision = validator.evaluate(
            host: "example.com",
            port: 2222,
            keyType: "ssh-ed25519",
            publicKey: "BBBB",
            fingerprint: "SHA256:xyz789"
        )

        #expect(decision == .trustOnFirstUse)
        #expect(store.all.count == 2)
    }

    // MARK: - InMemoryKnownHostStore

    @Test("InMemoryKnownHostStore.remove deletes the record")
    @MainActor func storeRemoveDeletesRecord() {
        let host = KnownHost(
            host: "example.com",
            port: 22,
            keyType: "ssh-ed25519",
            publicKey: "AAAA",
            fingerprint: "SHA256:abc123"
        )
        let store = InMemoryKnownHostStore(seed: [host])

        store.remove(host: "example.com", port: 22)

        #expect(store.all.isEmpty)
        #expect(store.find(host: "example.com", port: 22) == nil)
    }

    @Test("InMemoryKnownHostStore.upsert replaces existing record")
    @MainActor func storeUpsertReplacesExisting() {
        let host1 = KnownHost(
            host: "example.com",
            port: 22,
            keyType: "ssh-ed25519",
            publicKey: "AAAA",
            fingerprint: "SHA256:old"
        )
        let store = InMemoryKnownHostStore(seed: [host1])

        let host2 = KnownHost(
            host: "example.com",
            port: 22,
            keyType: "ssh-ed25519",
            publicKey: "BBBB",
            fingerprint: "SHA256:new"
        )
        store.upsert(host2)

        #expect(store.all.count == 1)
        #expect(store.find(host: "example.com", port: 22)?.fingerprint == "SHA256:new")
    }

    @Test("trusted decision updates lastSeenAt")
    @MainActor func trustedUpdatesLastSeen() {
        let oldDate = Date(timeIntervalSince1970: 1_000_000)
        let existing = KnownHost(
            host: "example.com",
            port: 22,
            keyType: "ssh-ed25519",
            publicKey: "AAAA",
            fingerprint: "SHA256:abc123",
            lastSeenAt: oldDate
        )
        let store = InMemoryKnownHostStore(seed: [existing])
        let validator = HostKeyValidator(store: store)

        _ = validator.evaluate(
            host: "example.com",
            port: 22,
            keyType: "ssh-ed25519",
            publicKey: "AAAA",
            fingerprint: "SHA256:abc123"
        )

        let record = store.find(host: "example.com", port: 22)!
        #expect(record.lastSeenAt > oldDate)
    }
}
