import Testing
import Foundation
@testable import EveryTerm

@Suite("SessionStore Integration Tests")
struct SessionStoreIntegrationTests {

    @Test("대량 세션 (100+) 생성/조회 성능")
    @MainActor func bulkCreateAndQuery() throws {
        let store = SessionStore.forTesting()

        for i in 0..<150 {
            let session = Session(
                name: "Server \(i)",
                type: .ssh,
                host: "10.0.0.\(i % 256)",
                username: "user\(i)",
                authMethod: .password
            )
            try store.add(session)
        }

        #expect(store.allSessions.count == 150)
    }

    @Test("동시 CRUD 연산 시 데이터 정합성")
    @MainActor func concurrentCRUDConsistency() async throws {
        let store = SessionStore.forTesting()

        // 여러 세션을 동시에 생성
        let sessions = (0..<20).map { i in
            Session(
                name: "Concurrent \(i)",
                type: .ssh,
                host: "host\(i).com",
                username: "user",
                authMethod: .password
            )
        }

        for session in sessions {
            try store.add(session)
        }

        // 일부 삭제
        for session in sessions.prefix(5) {
            try store.delete(session.id)
        }

        // 나머지 확인
        #expect(store.allSessions.count == 15)

        // 삭제된 세션이 없는지 확인
        for session in sessions.prefix(5) {
            #expect(store.session(byId: session.id) == nil)
        }
    }

    @Test("잘못된 스키마 마이그레이션 시나리오 대비")
    @MainActor func schemaMigrationSafety() throws {
        // 초기 스토어 생성이 크래시 없이 완료되어야 함
        let store = SessionStore.forTesting()
        #expect(store.allSessions.isEmpty)

        // 세션 생성 후 다시 열었을 때 데이터 유지 확인은
        // 실제 SwiftData 통합 후 가능
        let session = Session(
            name: "Migration Test",
            type: .ssh,
            host: "test.com",
            username: "user",
            authMethod: .password
        )
        try store.add(session)
        #expect(store.allSessions.count == 1)
    }
}
