import Testing
import Foundation
@testable import EveryTerm

@Suite("SSHKeyManager Tests")
struct SSHKeyManagerTests {

    // MARK: - [보통] 키 파싱

    @Test("RSA 공개키 파일 파싱")
    func parseRSAPublicKey() throws {
        let rsaKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQ... user@host"
        let manager = SSHKeyManager()
        let keyInfo = try manager.parsePublicKey(rsaKey)

        #expect(keyInfo.type == .rsa)
        #expect(keyInfo.comment == "user@host")
    }

    @Test("Ed25519 공개키 파일 파싱")
    func parseEd25519PublicKey() throws {
        let ed25519Key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... user@host"
        let manager = SSHKeyManager()
        let keyInfo = try manager.parsePublicKey(ed25519Key)

        #expect(keyInfo.type == .ed25519)
    }

    @Test("ECDSA 공개키 파일 파싱")
    func parseECDSAPublicKey() throws {
        let ecdsaKey = "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTY... user@host"
        let manager = SSHKeyManager()
        let keyInfo = try manager.parsePublicKey(ecdsaKey)

        #expect(keyInfo.type == .ecdsa)
    }

    @Test("잘못된 형식의 키 파일 에러 처리")
    func invalidKeyFormatThrows() {
        let invalidKey = "not-a-valid-key-format"
        let manager = SSHKeyManager()

        #expect(throws: SSHKeyError.self) {
            try manager.parsePublicKey(invalidKey)
        }
    }

    @Test("~/.ssh/ 디렉토리 스캔 결과 목록 반환")
    func listSSHKeys() async throws {
        let manager = SSHKeyManager()
        let keys = try await manager.listKeys()

        // 결과는 배열이어야 함 (비어있을 수 있음)
        #expect(keys is [SSHKeyInfo])
    }

    // MARK: - [어려움] 키 생성

    @Test("Ed25519 키 생성 후 파일 존재 확인")
    func generateEd25519Key() async throws {
        let manager = SSHKeyManager()
        let testKeyName = "test_ed25519_\(UUID().uuidString)"

        let result = try await manager.generateKey(
            type: .ed25519,
            name: testKeyName,
            passphrase: nil
        )

        #expect(FileManager.default.fileExists(atPath: result.privateKeyPath))
        #expect(FileManager.default.fileExists(atPath: result.publicKeyPath))

        // Cleanup
        try? FileManager.default.removeItem(atPath: result.privateKeyPath)
        try? FileManager.default.removeItem(atPath: result.publicKeyPath)
    }

    @Test("RSA 키 생성 후 파일 존재 확인")
    func generateRSAKey() async throws {
        let manager = SSHKeyManager()
        let testKeyName = "test_rsa_\(UUID().uuidString)"

        let result = try await manager.generateKey(
            type: .rsa,
            name: testKeyName,
            passphrase: nil
        )

        #expect(FileManager.default.fileExists(atPath: result.privateKeyPath))
        #expect(FileManager.default.fileExists(atPath: result.publicKeyPath))

        try? FileManager.default.removeItem(atPath: result.privateKeyPath)
        try? FileManager.default.removeItem(atPath: result.publicKeyPath)
    }

    @Test("ECDSA 키 생성 후 파일 존재 확인")
    func generateECDSAKey() async throws {
        let manager = SSHKeyManager()
        let testKeyName = "test_ecdsa_\(UUID().uuidString)"

        let result = try await manager.generateKey(
            type: .ecdsa,
            name: testKeyName,
            passphrase: nil
        )

        #expect(FileManager.default.fileExists(atPath: result.privateKeyPath))
        #expect(FileManager.default.fileExists(atPath: result.publicKeyPath))

        try? FileManager.default.removeItem(atPath: result.privateKeyPath)
        try? FileManager.default.removeItem(atPath: result.publicKeyPath)
    }

    @Test("Passphrase가 KeychainManager에 저장되는지 확인")
    func passphraseStoredInKeychain() async throws {
        let manager = SSHKeyManager()
        let keychain = KeychainManager()
        let testKeyName = "test_pass_\(UUID().uuidString)"
        let passphrase = SecureBytes(utf8: "my-passphrase")

        let result = try await manager.generateKey(
            type: .ed25519,
            name: testKeyName,
            passphrase: passphrase
        )

        let stored = try await keychain.load(forKey: testKeyName)
        #expect(stored != nil)

        // Cleanup
        try? FileManager.default.removeItem(atPath: result.privateKeyPath)
        try? FileManager.default.removeItem(atPath: result.publicKeyPath)
        try? await keychain.delete(forKey: testKeyName)
    }

    @Test("이미 존재하는 키 이름으로 생성 시 에러")
    func duplicateKeyNameThrows() async throws {
        let manager = SSHKeyManager()
        let testKeyName = "test_dup_\(UUID().uuidString)"

        let result = try await manager.generateKey(type: .ed25519, name: testKeyName, passphrase: nil)

        do {
            _ = try await manager.generateKey(type: .ed25519, name: testKeyName, passphrase: nil)
            #expect(Bool(false), "이미 존재하는 키 이름으로 생성 시 에러가 throw되어야 한다")
        } catch {
            #expect(error is SSHKeyError)
        }

        try? FileManager.default.removeItem(atPath: result.privateKeyPath)
        try? FileManager.default.removeItem(atPath: result.publicKeyPath)
    }
}
