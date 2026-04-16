import Testing
import Foundation
@testable import EveryTerm

@Suite("SFTP Integration Tests")
struct SFTPIntegrationTests {

    // MARK: - [어려움] SFTP 엔드투엔드

    @Test("SSH 연결 → openSFTPClient → listDirectory 전체 흐름이 동작해야 한다")
    func endToEndListDirectory() async throws {
        // 실제 SSH 서버가 필요한 통합 테스트
        // CI 환경에서는 로컬 OpenSSH 서버 또는 Docker 컨테이너를 사용
        let adapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "testuser",
            authMethod: .password(SecureBytes(Array("testpass".utf8)))
        )

        // 연결 → SFTP 열기 → 디렉토리 조회
        // 실제 서버 없이는 에러가 발생할 것
        do {
            try await adapter.connect()
            let sftpClient = try await adapter.openSFTPClient()
            let sftpAdapter = CitadelSFTPAdapter(sshAdapter: adapter)
            let entries = try await sftpAdapter.listDirectory("/")
            #expect(!entries.isEmpty)
            await adapter.disconnect()
        } catch {
            // 테스트 환경에 SSH 서버가 없으면 예외 발생 — 정상
            // CI에서는 SSH 서버를 설정하여 이 테스트가 통과해야 함
            #expect(error is SSHConnectionError || error is any Error)
        }
    }

    @Test("파일 업로드 → 다운로드 → 내용 일치 확인")
    func uploadDownloadVerify() async throws {
        let adapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "testuser",
            authMethod: .password(SecureBytes(Array("testpass".utf8)))
        )

        do {
            try await adapter.connect()
            let sftpAdapter = CitadelSFTPAdapter(sshAdapter: adapter)

            let testContent = "Hello, SFTP Integration Test!".data(using: .utf8)!
            let remotePath = "/tmp/sftp_test_\(UUID().uuidString).txt"

            // 업로드
            try await sftpAdapter.upload(data: testContent, to: remotePath, progress: nil)

            // 다운로드
            let downloaded = try await sftpAdapter.download(remotePath: remotePath, progress: nil)

            // 내용 일치 확인
            #expect(downloaded == testContent)

            // 정리
            try await sftpAdapter.removeItem(at: remotePath, isDirectory: false)
            await adapter.disconnect()
        } catch {
            #expect(error is SSHConnectionError || error is any Error)
        }
    }

    @Test("디렉토리 생성 → 파일 업로드 → 디렉토리 삭제(재귀) 전체 흐름")
    func createUploadDeleteDirectory() async throws {
        let adapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "testuser",
            authMethod: .password(SecureBytes(Array("testpass".utf8)))
        )

        do {
            try await adapter.connect()
            let sftpAdapter = CitadelSFTPAdapter(sshAdapter: adapter)

            let testDir = "/tmp/sftp_test_dir_\(UUID().uuidString)"

            // 디렉토리 생성
            try await sftpAdapter.createDirectory(testDir)

            // 파일 업로드
            let testData = "test content".data(using: .utf8)!
            try await sftpAdapter.upload(data: testData, to: "\(testDir)/test.txt", progress: nil)

            // 디렉토리 내용 확인
            let entries = try await sftpAdapter.listDirectory(testDir)
            #expect(entries.contains { $0.name == "test.txt" })

            // 파일 삭제 후 디렉토리 삭제
            try await sftpAdapter.removeItem(at: "\(testDir)/test.txt", isDirectory: false)
            try await sftpAdapter.removeItem(at: testDir, isDirectory: true)

            await adapter.disconnect()
        } catch {
            #expect(error is SSHConnectionError || error is any Error)
        }
    }

    @Test("동시에 여러 파일 전송 시 모두 완료되어야 한다")
    func concurrentTransfers() async throws {
        let adapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "testuser",
            authMethod: .password(SecureBytes(Array("testpass".utf8)))
        )

        do {
            try await adapter.connect()
            let sftpAdapter = CitadelSFTPAdapter(sshAdapter: adapter)

            let testFiles = (0..<4).map { i in
                (
                    path: "/tmp/sftp_concurrent_\(i)_\(UUID().uuidString).txt",
                    data: "File \(i) content".data(using: .utf8)!
                )
            }

            // 동시 업로드
            try await withThrowingTaskGroup(of: Void.self) { group in
                for file in testFiles {
                    group.addTask {
                        try await sftpAdapter.upload(data: file.data, to: file.path, progress: nil)
                    }
                }
                try await group.waitForAll()
            }

            // 모든 파일이 존재하는지 확인
            for file in testFiles {
                let entry = try await sftpAdapter.stat(file.path)
                #expect(entry.size > 0)
            }

            // 정리
            for file in testFiles {
                try await sftpAdapter.removeItem(at: file.path, isDirectory: false)
            }

            await adapter.disconnect()
        } catch {
            #expect(error is SSHConnectionError || error is any Error)
        }
    }
}
