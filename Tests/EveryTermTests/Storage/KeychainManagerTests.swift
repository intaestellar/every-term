import Testing
import Foundation
@testable import EveryTerm

@Suite("KeychainManager Tests")
struct KeychainManagerTests {

    @Test("save 후 load 라운드트립 일치")
    func saveAndLoadRoundTrip() async throws {
        let manager = KeychainManager()
        let password = SecureBytes(utf8: "mySecret123")
        let key = "test-save-load-\(UUID().uuidString)"

        try await manager.save(password: password, forKey: key)
        let loaded = try await manager.load(forKey: key)

        let loadedValue = try #require(loaded)
        #expect(Array(loadedValue) == Array(password))

        // Cleanup
        try await manager.delete(forKey: key)
    }

    @Test("존재하지 않는 키 load 시 nil 반환")
    func loadNonExistentKeyReturnsNil() async throws {
        let manager = KeychainManager()
        let result = try await manager.load(forKey: "non-existent-key-\(UUID().uuidString)")
        #expect(result == nil)
    }

    @Test("delete 후 load 시 nil 반환")
    func deleteRemovesEntry() async throws {
        let manager = KeychainManager()
        let key = "test-delete-\(UUID().uuidString)"
        let password = SecureBytes(utf8: "toBeDeleted")

        try await manager.save(password: password, forKey: key)
        try await manager.delete(forKey: key)
        let result = try await manager.load(forKey: key)

        #expect(result == nil)
    }

    @Test("동일 키에 덮어쓰기 후 새 값 반환")
    func overwriteWithSameKey() async throws {
        let manager = KeychainManager()
        let key = "test-overwrite-\(UUID().uuidString)"

        try await manager.save(password: SecureBytes(utf8: "first"), forKey: key)
        try await manager.save(password: SecureBytes(utf8: "second"), forKey: key)

        let loaded = try await manager.load(forKey: key)
        let value = try #require(loaded)
        #expect(Array(value) == Array(SecureBytes(utf8: "second")))

        try await manager.delete(forKey: key)
    }

    @Test("빈 SecureBytes 저장/불러오기")
    func saveAndLoadEmptyBytes() async throws {
        let manager = KeychainManager()
        let key = "test-empty-\(UUID().uuidString)"
        let empty = SecureBytes()

        try await manager.save(password: empty, forKey: key)
        let loaded = try await manager.load(forKey: key)

        let value = try #require(loaded)
        #expect(value.count == 0)

        try await manager.delete(forKey: key)
    }

    @Test("actor isolation — async 호출이 정상 동작")
    func actorIsolation() async throws {
        let manager = KeychainManager()
        let key = "test-actor-\(UUID().uuidString)"

        // 여러 async 호출이 순차적으로 실행되어야 함
        try await manager.save(password: SecureBytes(utf8: "async-test"), forKey: key)
        let result = try await manager.load(forKey: key)
        #expect(result != nil)

        try await manager.delete(forKey: key)
    }
}
