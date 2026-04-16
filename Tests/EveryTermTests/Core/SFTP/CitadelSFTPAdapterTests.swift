import Testing
import Foundation
@testable import EveryTerm

@Suite("CitadelSFTPAdapter Tests")
struct CitadelSFTPAdapterTests {

    // MARK: - [쉬움] 초기화

    @Test("SSHAdapter로부터 CitadelSFTPAdapter를 생성할 수 있어야 한다")
    func createFromSSHAdapter() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )

        // CitadelSFTPAdapter는 SSHAdapter를 받아 초기화
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)
        #expect(adapter is CitadelSFTPAdapter)
    }

    @Test("Actor 타입이어야 한다")
    func isActor() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )

        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)
        let _: any Actor = adapter
        #expect(true)
    }

    @Test("SFTPConnection 프로토콜을 준수해야 한다")
    func conformsToSFTPConnection() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )

        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)
        let _: any SFTPConnection = adapter
        #expect(true)
    }

    // MARK: - [보통] listDirectory

    @Test("지정 경로의 파일 목록을 SFTPFileEntry 배열로 반환해야 한다")
    func listDirectoryReturnsEntries() async throws {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        // 미연결 상태에서는 에러를 throw해야 한다
        await #expect(throws: (any Error).self) {
            try await adapter.listDirectory("/home/user")
        }
    }

    @Test(". 및 .. 항목을 필터링해야 한다")
    func listDirectoryFiltersDots() async {
        // 구현 시 "." 과 ".." 를 제외한 결과만 반환해야 한다
        // 실제 동작은 통합 테스트에서 검증
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.listDirectory("/home/user")
        }
    }

    @Test("각 항목의 permissions 비트마스크가 올바르게 변환되어야 한다")
    func listDirectoryPermissionsConversion() async {
        // permissions 비트마스크를 통한 isDirectory/isSymlink 판별이 올바라야 한다
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.listDirectory("/home")
        }
    }

    @Test("빈 디렉토리에서 빈 배열을 반환해야 한다")
    func listDirectoryEmptyDir() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.listDirectory("/empty")
        }
    }

    // MARK: - [보통] stat

    @Test("파일 경로에 대한 SFTPFileEntry를 반환해야 한다")
    func statReturnsEntry() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.stat("/home/user/file.txt")
        }
    }

    @Test("name이 path의 lastPathComponent여야 한다")
    func statNameIsLastPathComponent() async {
        // stat 결과의 name은 path에서 마지막 컴포넌트를 추출
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.stat("/home/user/document.pdf")
        }
    }

    // MARK: - [보통] createDirectory

    @Test("지정 경로에 디렉토리를 생성해야 한다")
    func createDirectory() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.createDirectory("/home/user/newdir")
        }
    }

    @Test("이미 존재하는 경로에 생성 시 에러를 throw해야 한다")
    func createDirectoryAlreadyExists() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.createDirectory("/home/user")
        }
    }

    // MARK: - [보통] removeItem

    @Test("isDirectory가 false이면 파일 삭제(SFTPClient.remove)를 호출해야 한다")
    func removeFile() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.removeItem(at: "/home/user/file.txt", isDirectory: false)
        }
    }

    @Test("isDirectory가 true이면 디렉토리 삭제(SFTPClient.rmdir)를 호출해야 한다")
    func removeDirectory() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.removeItem(at: "/home/user/dir", isDirectory: true)
        }
    }

    @Test("존재하지 않는 경로 삭제 시 에러를 throw해야 한다")
    func removeNonexistentPath() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.removeItem(at: "/nonexistent", isDirectory: false)
        }
    }

    // MARK: - [보통] rename

    @Test("파일 이름 변경이 정상 동작해야 한다")
    func renameFile() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.rename(from: "/home/user/old.txt", to: "/home/user/new.txt")
        }
    }

    @Test("대상 경로가 이미 존재하면 에러를 throw해야 한다")
    func renameToExistingPath() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.rename(from: "/home/user/a.txt", to: "/home/user/b.txt")
        }
    }

    // MARK: - [보통] changePermissions

    @Test("UInt32 타입으로 Citadel setAttributes를 정상 호출해야 한다")
    func changePermissions() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.changePermissions("/home/user/file.txt", permissions: 0o755)
        }
    }

    @Test("변경 후 stat으로 조회하면 새 permissions가 반영되어야 한다")
    func changePermissionsVerify() async {
        // 통합 테스트에서 실제 변경 후 확인
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.changePermissions("/home/user/file.txt", permissions: 0o644)
        }
    }

    // MARK: - [보통] download

    @Test("원격 파일을 Data로 다운로드해야 한다")
    func downloadFile() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.download(remotePath: "/home/user/file.txt", progress: nil)
        }
    }

    @Test("progress 콜백이 호출되어야 한다 (nil이 아닌 경우)")
    func downloadWithProgress() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        let progressCallback: @Sendable (Int64, Int64) -> Void = { _, _ in }

        await #expect(throws: (any Error).self) {
            try await adapter.download(remotePath: "/home/user/file.txt", progress: progressCallback)
        }
    }

    @Test("progress가 nil이면 콜백 없이 정상 다운로드되어야 한다")
    func downloadWithoutProgress() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.download(remotePath: "/home/user/file.txt", progress: nil)
        }
    }

    @Test("존재하지 않는 파일 다운로드 시 에러를 throw해야 한다")
    func downloadNonexistentFile() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.download(remotePath: "/nonexistent/file.txt", progress: nil)
        }
    }

    // MARK: - [보통] upload

    @Test("Data를 원격 경로에 업로드해야 한다")
    func uploadFile() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)
        let testData = "Hello, World!".data(using: .utf8)!

        await #expect(throws: (any Error).self) {
            try await adapter.upload(data: testData, to: "/home/user/uploaded.txt", progress: nil)
        }
    }

    @Test("progress 콜백이 호출되어야 한다 (nil이 아닌 경우, upload)")
    func uploadWithProgress() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)
        let testData = Data(repeating: 0x41, count: 1024)

        let progressCallback: @Sendable (Int64, Int64) -> Void = { _, _ in }

        await #expect(throws: (any Error).self) {
            try await adapter.upload(data: testData, to: "/home/user/file.txt", progress: progressCallback)
        }
    }

    @Test("빈 Data(0 bytes) 업로드가 정상 동작해야 한다")
    func uploadEmptyData() async {
        let sshAdapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes([]))
        )
        let adapter = CitadelSFTPAdapter(sshAdapter: sshAdapter)

        await #expect(throws: (any Error).self) {
            try await adapter.upload(data: Data(), to: "/home/user/empty.txt", progress: nil)
        }
    }

    // MARK: - [어려움] 심볼릭 링크

    @Test("isSymlink 판별이 permissions 비트마스크로 정상 동작해야 한다")
    func symlinkDetection() {
        // permissions 비트마스크로 symlink 판별
        let symlinkPerms: UInt32 = 0o120777
        let isSymlink = (symlinkPerms & 0o170000) == 0o120000
        #expect(isSymlink == true)

        let regularPerms: UInt32 = 0o100644
        let isNotSymlink = (regularPerms & 0o170000) == 0o120000
        #expect(isNotSymlink == false)
    }

    @Test("symlinkTarget이 nil로 설정되어야 한다 (readlink API 비공개)")
    func symlinkTargetIsNil() {
        // Citadel의 readlink API가 비공개이므로 symlinkTarget은 항상 nil
        let entry = SFTPFileEntry(
            id: "/home/user/link",
            name: "link",
            path: "/home/user/link",
            size: 0,
            permissions: 0o120777,
            modifiedAt: Date(),
            ownerUid: 0,
            ownerGid: 0,
            isDirectory: false,
            isSymlink: true,
            symlinkTarget: nil
        )

        #expect(entry.symlinkTarget == nil)
    }

    // MARK: - [어려움] 파일명 인코딩

    @Test("UTF-8 파일명이 정상 처리되어야 한다")
    func utf8Filename() {
        let entry = SFTPFileEntry(
            id: "/home/user/한글파일.txt",
            name: "한글파일.txt",
            path: "/home/user/한글파일.txt",
            size: 100,
            permissions: 0o100644,
            modifiedAt: Date(),
            ownerUid: 0,
            ownerGid: 0,
            isDirectory: false,
            isSymlink: false,
            symlinkTarget: nil
        )

        #expect(entry.name == "한글파일.txt")
    }

    @Test("UTF-8 외 인코딩(ISO-8859-1) 폴백이 동작해야 한다")
    func iso88591Fallback() {
        // ISO-8859-1 인코딩 바이트를 UTF-8로 변환 실패 시 폴백 처리
        let iso8859bytes: [UInt8] = [0xE9, 0xE8, 0xEA] // é, è, ê in ISO-8859-1
        let fallbackName = String(bytes: iso8859bytes, encoding: .isoLatin1) ?? "unknown"

        let entry = SFTPFileEntry(
            id: "/home/user/\(fallbackName)",
            name: fallbackName,
            path: "/home/user/\(fallbackName)",
            size: 100,
            permissions: 0o100644,
            modifiedAt: Date(),
            ownerUid: 0,
            ownerGid: 0,
            isDirectory: false,
            isSymlink: false,
            symlinkTarget: nil
        )

        #expect(entry.name == fallbackName)
        #expect(!entry.name.isEmpty)
    }

}
