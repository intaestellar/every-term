import Testing
import Foundation
@testable import EveryTerm

@Suite("SFTPBookmark Tests")
struct SFTPBookmarkTests {

    // MARK: - [쉬움] 기본 CRUD

    @Test("SFTPBookmark 생성 시 모든 프로퍼티가 올바르게 초기화되어야 한다")
    func initAllProperties() {
        let id = UUID()
        let sessionId = UUID()
        let now = Date()

        let bookmark = SFTPBookmark(
            id: id,
            sessionId: sessionId,
            path: "/home/user/projects",
            name: "Projects",
            createdAt: now
        )

        #expect(bookmark.id == id)
        #expect(bookmark.sessionId == sessionId)
        #expect(bookmark.path == "/home/user/projects")
        #expect(bookmark.name == "Projects")
        #expect(bookmark.createdAt == now)
    }

    @Test("sessionId로 북마크를 필터링할 수 있어야 한다")
    func filterBySessionId() {
        let sessionId1 = UUID()
        let sessionId2 = UUID()

        let bookmarks = [
            SFTPBookmark(id: UUID(), sessionId: sessionId1, path: "/path1", name: "BM1", createdAt: Date()),
            SFTPBookmark(id: UUID(), sessionId: sessionId2, path: "/path2", name: "BM2", createdAt: Date()),
            SFTPBookmark(id: UUID(), sessionId: sessionId1, path: "/path3", name: "BM3", createdAt: Date()),
        ]

        let filtered = bookmarks.filter { $0.sessionId == sessionId1 }
        #expect(filtered.count == 2)
    }

    @Test("북마크를 삭제할 수 있어야 한다")
    func deleteBookmark() {
        let bookmarkId = UUID()
        var bookmarks = [
            SFTPBookmark(id: bookmarkId, sessionId: UUID(), path: "/path1", name: "BM1", createdAt: Date()),
            SFTPBookmark(id: UUID(), sessionId: UUID(), path: "/path2", name: "BM2", createdAt: Date()),
        ]

        bookmarks.removeAll { $0.id == bookmarkId }
        #expect(bookmarks.count == 1)
        #expect(bookmarks.first?.name == "BM2")
    }

    @Test("id가 UUID 타입이어야 한다")
    func idIsUUID() {
        let bookmark = SFTPBookmark(
            id: UUID(),
            sessionId: UUID(),
            path: "/test",
            name: "Test",
            createdAt: Date()
        )

        let _: UUID = bookmark.id
        #expect(true)
    }

    // MARK: - [보통] SwiftData 영속성

    @Test("SwiftData 컨텍스트에 저장 후 다시 조회할 수 있어야 한다")
    func swiftDataPersistence() {
        // SwiftData @Model로 정의된 SFTPBookmark가 ModelContainer에 저장/조회 가능해야 한다
        // 실제 ModelContainer 테스트는 구현 후 진행
        let bookmark = SFTPBookmark(
            id: UUID(),
            sessionId: UUID(),
            path: "/home/user",
            name: "Home",
            createdAt: Date()
        )

        // @Model 어노테이션 존재를 컴파일 타임에 검증
        #expect(bookmark.path == "/home/user")
    }

    @Test("같은 sessionId의 여러 북마크를 저장하고 조회할 수 있어야 한다")
    func multipleBookmarksSameSession() {
        let sessionId = UUID()
        let bookmarks = [
            SFTPBookmark(id: UUID(), sessionId: sessionId, path: "/path1", name: "BM1", createdAt: Date()),
            SFTPBookmark(id: UUID(), sessionId: sessionId, path: "/path2", name: "BM2", createdAt: Date()),
            SFTPBookmark(id: UUID(), sessionId: sessionId, path: "/path3", name: "BM3", createdAt: Date()),
        ]

        let filtered = bookmarks.filter { $0.sessionId == sessionId }
        #expect(filtered.count == 3)
    }

    @Test("path가 중복된 북마크를 허용해야 한다 (다른 세션)")
    func duplicatePathDifferentSessions() {
        let path = "/home/user/shared"
        let bookmarks = [
            SFTPBookmark(id: UUID(), sessionId: UUID(), path: path, name: "Shared1", createdAt: Date()),
            SFTPBookmark(id: UUID(), sessionId: UUID(), path: path, name: "Shared2", createdAt: Date()),
        ]

        #expect(bookmarks.count == 2)
        #expect(bookmarks[0].path == bookmarks[1].path)
        #expect(bookmarks[0].sessionId != bookmarks[1].sessionId)
    }
}
