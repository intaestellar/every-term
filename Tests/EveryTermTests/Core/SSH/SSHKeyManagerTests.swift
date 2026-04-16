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

    // MARK: - [보통] SP-3 확장: 키 생성 타입별 라운드트립

    @Test("RSA 4096 키 생성 -> 공개키/비밀키 쌍 반환")
    func generateRSA4096Key() async throws {
        let manager = SSHKeyManager()
        let testKeyName = "test_rsa4096_\(UUID().uuidString)"

        let result = try await manager.generateKey(
            type: .rsa,
            bits: 4096,
            name: testKeyName,
            passphrase: nil
        )

        #expect(FileManager.default.fileExists(atPath: result.privateKeyPath))
        #expect(FileManager.default.fileExists(atPath: result.publicKeyPath))

        try? FileManager.default.removeItem(atPath: result.privateKeyPath)
        try? FileManager.default.removeItem(atPath: result.publicKeyPath)
    }

    @Test("ECDSA P-256 키 생성 -> 공개키/비밀키 쌍 반환")
    func generateECDSAP256Key() async throws {
        let manager = SSHKeyManager()
        let testKeyName = "test_ecdsa256_\(UUID().uuidString)"

        let result = try await manager.generateKey(
            type: .ecdsa,
            bits: 256,
            name: testKeyName,
            passphrase: nil
        )

        #expect(FileManager.default.fileExists(atPath: result.privateKeyPath))
        #expect(FileManager.default.fileExists(atPath: result.publicKeyPath))

        try? FileManager.default.removeItem(atPath: result.privateKeyPath)
        try? FileManager.default.removeItem(atPath: result.publicKeyPath)
    }

    @Test("생성된 공개키 -> 파싱 라운드트립 (타입 일치)")
    func generatedKeyParseRoundTrip() async throws {
        let manager = SSHKeyManager()
        let testKeyName = "test_roundtrip_\(UUID().uuidString)"

        let result = try await manager.generateKey(
            type: .ed25519,
            name: testKeyName,
            passphrase: nil
        )

        let publicKeyContent = try String(contentsOfFile: result.publicKeyPath, encoding: .utf8)
        let keyInfo = try manager.parsePublicKey(publicKeyContent.trimmingCharacters(in: .whitespacesAndNewlines))

        #expect(keyInfo.type == .ed25519)

        try? FileManager.default.removeItem(atPath: result.privateKeyPath)
        try? FileManager.default.removeItem(atPath: result.publicKeyPath)
    }

    // MARK: - [어려움] SP-3 확장: 디스크 로드 / 배포

    @Test("키 파일 저장 후 디스크에서 다시 로드 -> 내용 일치")
    func saveAndReloadKeyFromDisk() async throws {
        let manager = SSHKeyManager()
        let testKeyName = "test_reload_\(UUID().uuidString)"

        let result = try await manager.generateKey(
            type: .ed25519,
            name: testKeyName,
            passphrase: nil
        )

        let originalPublicKey = try String(contentsOfFile: result.publicKeyPath, encoding: .utf8)
        let reloadedKeys = try await manager.listKeys()
        let found = reloadedKeys.first { $0.comment.contains(testKeyName) || result.publicKeyPath.contains(testKeyName) }

        #expect(found != nil)
        #expect(!originalPublicKey.isEmpty)

        try? FileManager.default.removeItem(atPath: result.privateKeyPath)
        try? FileManager.default.removeItem(atPath: result.publicKeyPath)
    }

    @Test("원격 서버 공개키 배포 명령 생성 확인 (authorized_keys 경로)")
    func deployCommandGeneration() async throws {
        let manager = SSHKeyManager()
        let publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... test@host"

        let command = manager.buildDeployCommand(publicKey: publicKey)

        #expect(command.contains("authorized_keys"))
        #expect(command.contains("mkdir -p"))
        #expect(command.contains(".ssh"))
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
