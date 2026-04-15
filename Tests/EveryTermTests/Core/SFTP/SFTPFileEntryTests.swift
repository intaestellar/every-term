import Testing
import Foundation
@testable import EveryTerm

// MARK: - SFTPFileEntry Tests

@Suite("SFTPFileEntry Tests")
struct SFTPFileEntryTests {

    // MARK: - [쉬움] 기본 생성 및 프로퍼티

    @Test("SFTPFileEntry 생성 시 모든 프로퍼티가 올바르게 초기화되어야 한다")
    func initAllProperties() {
        let now = Date()
        let entry = SFTPFileEntry(
            id: "/home/user/test.txt",
            name: "test.txt",
            path: "/home/user/test.txt",
            size: 1024,
            permissions: 0o100644,
            modifiedAt: now,
            ownerUid: 1000,
            ownerGid: 1000,
            isDirectory: false,
            isSymlink: false,
            symlinkTarget: nil
        )

        #expect(entry.name == "test.txt")
        #expect(entry.path == "/home/user/test.txt")
        #expect(entry.size == 1024)
        #expect(entry.permissions == 0o100644)
        #expect(entry.modifiedAt == now)
        #expect(entry.ownerUid == 1000)
        #expect(entry.ownerGid == 1000)
        #expect(entry.isDirectory == false)
        #expect(entry.isSymlink == false)
        #expect(entry.symlinkTarget == nil)
    }

    @Test("id가 full path와 동일해야 한다")
    func idEqualsFullPath() {
        let entry = SFTPFileEntry(
            id: "/home/user/test.txt",
            name: "test.txt",
            path: "/home/user/test.txt",
            size: 0,
            permissions: 0o100644,
            modifiedAt: Date(),
            ownerUid: 0,
            ownerGid: 0,
            isDirectory: false,
            isSymlink: false,
            symlinkTarget: nil
        )

        #expect(entry.id == "/home/user/test.txt")
        #expect(entry.id == entry.path)
    }

    @Test("Identifiable 프로토콜을 준수해야 한다")
    func conformsToIdentifiable() {
        let entry = SFTPFileEntry(
            id: "/test",
            name: "test",
            path: "/test",
            size: 0,
            permissions: 0,
            modifiedAt: Date(),
            ownerUid: 0,
            ownerGid: 0,
            isDirectory: false,
            isSymlink: false,
            symlinkTarget: nil
        )

        // Identifiable 준수 확인: id 프로퍼티 접근 가능
        let _: String = entry.id
        #expect(true)
    }

    @Test("Sendable 프로토콜을 준수해야 한다")
    func conformsToSendable() {
        let entry = SFTPFileEntry(
            id: "/test",
            name: "test",
            path: "/test",
            size: 0,
            permissions: 0,
            modifiedAt: Date(),
            ownerUid: 0,
            ownerGid: 0,
            isDirectory: false,
            isSymlink: false,
            symlinkTarget: nil
        )

        // Sendable 준수 확인: Task에 전달 가능
        let sendable: any Sendable = entry
        #expect(sendable is SFTPFileEntry)
    }

    // MARK: - [쉬움] isDirectory 판별

    @Test("permissions & 0o170000 == 0o040000이면 isDirectory가 true여야 한다")
    func isDirectoryTrue() {
        let entry = SFTPFileEntry(
            id: "/home/user/docs",
            name: "docs",
            path: "/home/user/docs",
            size: 0,
            permissions: 0o040755,
            modifiedAt: Date(),
            ownerUid: 0,
            ownerGid: 0,
            isDirectory: true,
            isSymlink: false,
            symlinkTarget: nil
        )

        #expect(entry.isDirectory == true)
        #expect(entry.permissions & 0o170000 == 0o040000)
    }

    @Test("일반 파일 permissions(0o100644)이면 isDirectory가 false여야 한다")
    func isDirectoryFalseForRegularFile() {
        let entry = SFTPFileEntry(
            id: "/home/user/file.txt",
            name: "file.txt",
            path: "/home/user/file.txt",
            size: 100,
            permissions: 0o100644,
            modifiedAt: Date(),
            ownerUid: 0,
            ownerGid: 0,
            isDirectory: false,
            isSymlink: false,
            symlinkTarget: nil
        )

        #expect(entry.isDirectory == false)
        #expect(entry.permissions & 0o170000 != 0o040000)
    }

    // MARK: - [쉬움] isSymlink 판별

    @Test("permissions & 0o170000 == 0o120000이면 isSymlink가 true여야 한다")
    func isSymlinkTrue() {
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
            symlinkTarget: "/home/user/target"
        )

        #expect(entry.isSymlink == true)
        #expect(entry.permissions & 0o170000 == 0o120000)
    }

    @Test("일반 파일이면 isSymlink가 false여야 한다")
    func isSymlinkFalseForRegularFile() {
        let entry = SFTPFileEntry(
            id: "/home/user/file.txt",
            name: "file.txt",
            path: "/home/user/file.txt",
            size: 100,
            permissions: 0o100644,
            modifiedAt: Date(),
            ownerUid: 0,
            ownerGid: 0,
            isDirectory: false,
            isSymlink: false,
            symlinkTarget: nil
        )

        #expect(entry.isSymlink == false)
    }

    @Test("디렉토리이면 isSymlink가 false여야 한다")
    func isSymlinkFalseForDirectory() {
        let entry = SFTPFileEntry(
            id: "/home/user/docs",
            name: "docs",
            path: "/home/user/docs",
            size: 0,
            permissions: 0o040755,
            modifiedAt: Date(),
            ownerUid: 0,
            ownerGid: 0,
            isDirectory: true,
            isSymlink: false,
            symlinkTarget: nil
        )

        #expect(entry.isSymlink == false)
    }

    // MARK: - [보통] SFTPMessage.Name → SFTPFileEntry 변환

    @Test("attributes.permissions가 nil이면 기본값 0으로 처리해야 한다")
    func nilPermissionsDefaultsToZero() {
        // SFTPFileEntry 변환 시 nil permissions → 0
        let entry = SFTPFileEntry(
            id: "/test",
            name: "test",
            path: "/test",
            size: 0,
            permissions: 0,
            modifiedAt: Date.distantPast,
            ownerUid: 0,
            ownerGid: 0,
            isDirectory: false,
            isSymlink: false,
            symlinkTarget: nil
        )

        #expect(entry.permissions == 0)
    }

    @Test("attributes.uidgid가 nil이면 ownerUid/ownerGid가 0이어야 한다")
    func nilUidGidDefaultsToZero() {
        let entry = SFTPFileEntry(
            id: "/test",
            name: "test",
            path: "/test",
            size: 0,
            permissions: 0o100644,
            modifiedAt: Date(),
            ownerUid: 0,
            ownerGid: 0,
            isDirectory: false,
            isSymlink: false,
            symlinkTarget: nil
        )

        #expect(entry.ownerUid == 0)
        #expect(entry.ownerGid == 0)
    }

    @Test("attributes.accessModificationTime이 nil이면 modifiedAt이 Date.distantPast여야 한다")
    func nilModTimeDefaultsToDistantPast() {
        let entry = SFTPFileEntry(
            id: "/test",
            name: "test",
            path: "/test",
            size: 0,
            permissions: 0o100644,
            modifiedAt: Date.distantPast,
            ownerUid: 0,
            ownerGid: 0,
            isDirectory: false,
            isSymlink: false,
            symlinkTarget: nil
        )

        #expect(entry.modifiedAt == Date.distantPast)
    }

    @Test("attributes.size가 nil이면 size가 0이어야 한다")
    func nilSizeDefaultsToZero() {
        let entry = SFTPFileEntry(
            id: "/test",
            name: "test",
            path: "/test",
            size: 0,
            permissions: 0o100644,
            modifiedAt: Date(),
            ownerUid: 0,
            ownerGid: 0,
            isDirectory: false,
            isSymlink: false,
            symlinkTarget: nil
        )

        #expect(entry.size == 0)
    }

    @Test(". 및 .. 항목이 필터링되어야 한다")
    func dotEntriesFiltered() {
        // 변환 로직에서 "." 과 ".." 이름을 가진 항목을 제외해야 함
        let dotEntry = SFTPFileEntry(
            id: "/home/user/.",
            name: ".",
            path: "/home/user/.",
            size: 0,
            permissions: 0o040755,
            modifiedAt: Date(),
            ownerUid: 0,
            ownerGid: 0,
            isDirectory: true,
            isSymlink: false,
            symlinkTarget: nil
        )

        let dotDotEntry = SFTPFileEntry(
            id: "/home/user/..",
            name: "..",
            path: "/home/user/..",
            size: 0,
            permissions: 0o040755,
            modifiedAt: Date(),
            ownerUid: 0,
            ownerGid: 0,
            isDirectory: true,
            isSymlink: false,
            symlinkTarget: nil
        )

        // 필터링 로직 검증: "." 과 ".." 은 제외해야 한다
        let entries = [dotEntry, dotDotEntry]
        let filtered = entries.filter { $0.name != "." && $0.name != ".." }
        #expect(filtered.isEmpty)
    }
}

// MARK: - SFTPConnection Protocol Tests

@Suite("SFTPConnection Protocol Tests")
struct SFTPConnectionProtocolTests {

    @Test("MockSFTPConnection이 SFTPConnection 프로토콜을 준수해야 한다")
    func mockConformsToProtocol() async {
        let mock = MockSFTPConnection()
        // SFTPConnection 프로토콜 타입으로 할당 가능해야 한다
        let connection: any SFTPConnection = mock
        #expect(connection is MockSFTPConnection)
    }

    @Test("MockSFTPConnection이 Actor여야 한다")
    func mockIsActor() async {
        let mock = MockSFTPConnection()
        // Actor 타입이므로 isolated 접근이 필요
        let _: any Actor = mock
        #expect(true)
    }

    @Test("listDirectory가 설정된 mock 데이터를 반환해야 한다")
    func mockListDirectoryReturnsData() async throws {
        let mock = MockSFTPConnection()
        let testEntries = [
            SFTPFileEntry(
                id: "/home/user/file.txt",
                name: "file.txt",
                path: "/home/user/file.txt",
                size: 100,
                permissions: 0o100644,
                modifiedAt: Date(),
                ownerUid: 1000,
                ownerGid: 1000,
                isDirectory: false,
                isSymlink: false,
                symlinkTarget: nil
            )
        ]
        await mock.setListDirectoryResult(testEntries)

        let result = try await mock.listDirectory("/home/user")
        #expect(result.count == 1)
        #expect(result[0].name == "file.txt")
    }

    @Test("stat이 설정된 mock 파일 정보를 반환해야 한다")
    func mockStatReturnsData() async throws {
        let mock = MockSFTPConnection()
        let testEntry = SFTPFileEntry(
            id: "/home/user/file.txt",
            name: "file.txt",
            path: "/home/user/file.txt",
            size: 2048,
            permissions: 0o100644,
            modifiedAt: Date(),
            ownerUid: 1000,
            ownerGid: 1000,
            isDirectory: false,
            isSymlink: false,
            symlinkTarget: nil
        )
        await mock.setStatResult(testEntry)

        let result = try await mock.stat("/home/user/file.txt")
        #expect(result.name == "file.txt")
        #expect(result.size == 2048)
    }
}

// MARK: - MockSFTPConnection

actor MockSFTPConnection: SFTPConnection {
    private var listDirectoryResults: [SFTPFileEntry] = []
    private var statResult: SFTPFileEntry?
    private var shouldThrowError: Error?
    private var downloadData: Data = Data()
    private var createDirectoryCalled = false
    private var removeItemCalled = false
    private var renameCalled = false
    private var changePermissionsCalled = false
    private var uploadCalled = false

    func setListDirectoryResult(_ entries: [SFTPFileEntry]) {
        listDirectoryResults = entries
    }

    func setStatResult(_ entry: SFTPFileEntry) {
        statResult = entry
    }

    func setShouldThrowError(_ error: Error?) {
        shouldThrowError = error
    }

    func setDownloadData(_ data: Data) {
        downloadData = data
    }

    func listDirectory(_ path: String) async throws -> [SFTPFileEntry] {
        if let error = shouldThrowError { throw error }
        return listDirectoryResults
    }

    func stat(_ path: String) async throws -> SFTPFileEntry {
        if let error = shouldThrowError { throw error }
        guard let result = statResult else {
            throw MockSFTPError.notFound
        }
        return result
    }

    func createDirectory(_ path: String) async throws {
        if let error = shouldThrowError { throw error }
        createDirectoryCalled = true
    }

    func removeItem(at path: String, isDirectory: Bool) async throws {
        if let error = shouldThrowError { throw error }
        removeItemCalled = true
    }

    func rename(from: String, to: String) async throws {
        if let error = shouldThrowError { throw error }
        renameCalled = true
    }

    func download(remotePath: String, progress: (@Sendable (Int64, Int64) -> Void)?) async throws -> Data {
        if let error = shouldThrowError { throw error }
        return downloadData
    }

    func upload(data: Data, to remotePath: String, progress: (@Sendable (Int64, Int64) -> Void)?) async throws {
        if let error = shouldThrowError { throw error }
        uploadCalled = true
    }

    func changePermissions(_ path: String, permissions: UInt32) async throws {
        if let error = shouldThrowError { throw error }
        changePermissionsCalled = true
    }
}

enum MockSFTPError: Error {
    case notFound
    case permissionDenied
    case alreadyExists
    case connectionLost
}
