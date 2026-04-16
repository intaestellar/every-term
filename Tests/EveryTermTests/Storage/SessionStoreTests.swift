import Testing
import Foundation
@testable import EveryTerm

@Suite("SessionStore CRUD Tests")
struct SessionStoreTests {

    @Test("세션 생성 후 목록 조회에 포함 확인")
    @MainActor func createAndList() async throws {
        let store = SessionStore.forTesting()
        let session = Session(
            name: "Test SSH",
            type: .ssh,
            host: "example.com",
            username: "admin",
            authMethod: .password
        )

        try store.add(session)
        let sessions = store.allSessions
        #expect(sessions.contains(where: { $0.id == session.id }))
    }

    @Test("세션 수정 후 변경사항 반영 확인")
    @MainActor func updateSession() async throws {
        let store = SessionStore.forTesting()
        let session = Session(
            name: "Before Update",
            type: .ssh,
            host: "old.com",
            username: "user",
            authMethod: .password
        )

        try store.add(session)
        try store.update(session.id, name: "After Update", host: "new.com")

        let updated = store.session(byId: session.id)
        #expect(updated?.name == "After Update")
        #expect(updated?.host == "new.com")
    }

    @Test("세션 삭제 후 목록에서 제거 확인")
    @MainActor func deleteSession() async throws {
        let store = SessionStore.forTesting()
        let session = Session(
            name: "To Delete",
            type: .ssh,
            host: "delete.com",
            username: "user",
            authMethod: .password
        )

        try store.add(session)
        try store.delete(session.id)

        #expect(store.session(byId: session.id) == nil)
    }

    @Test("그룹 생성/수정/삭제 CRUD")
    @MainActor func groupCRUD() async throws {
        let store = SessionStore.forTesting()
        let group = SessionGroup(name: "Dev Servers")

        try store.addGroup(group)
        #expect(store.allGroups.contains(where: { $0.id == group.id }))

        try store.updateGroup(group.id, name: "Production Servers")
        #expect(store.group(byId: group.id)?.name == "Production Servers")

        try store.deleteGroup(group.id)
        #expect(store.group(byId: group.id) == nil)
    }

    @Test("세션을 그룹에 배정 후 그룹별 조회")
    @MainActor func assignSessionToGroup() async throws {
        let store = SessionStore.forTesting()
        let group = SessionGroup(name: "Prod")
        let session = Session(
            name: "Prod SSH",
            type: .ssh,
            host: "prod.com",
            username: "deploy",
            authMethod: .key
        )

        try store.addGroup(group)
        try store.add(session)
        try store.assignToGroup(sessionId: session.id, groupId: group.id)

        let sessionsInGroup = store.sessions(inGroup: group.id)
        #expect(sessionsInGroup.contains(where: { $0.id == session.id }))
    }
}
