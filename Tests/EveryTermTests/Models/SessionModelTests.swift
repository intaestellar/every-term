import Testing
import Foundation
@testable import EveryTerm

@Suite("Session Model Tests")
struct SessionModelTests {

    @Test("필수 필드로 Session 생성 후 프로퍼티 일치 확인")
    @MainActor func createSessionWithRequiredFields() {
        let session = Session(
            name: "Test Server",
            type: .ssh,
            host: "192.168.1.1",
            username: "admin",
            authMethod: .password
        )

        #expect(session.name == "Test Server")
        #expect(session.type == .ssh)
        #expect(session.host == "192.168.1.1")
        #expect(session.username == "admin")
        #expect(session.authMethod == .password)
        #expect(session.id != UUID())
    }

    @Test("기본값 확인 — port, keepAliveInterval, createdAt 자동 설정")
    @MainActor func defaultValues() {
        let beforeCreation = Date()
        let session = Session(
            name: "Default Test",
            type: .ssh,
            host: "example.com",
            username: "user",
            authMethod: .key
        )

        #expect(session.port == 22)
        #expect(session.keepAliveInterval == 60)
        #expect(session.createdAt >= beforeCreation)
    }

    @Test("선택적 필드 nil 기본값 확인")
    @MainActor func optionalFieldsAreNil() {
        let session = Session(
            name: "Minimal",
            type: .local,
            host: "localhost",
            username: "me",
            authMethod: .password
        )

        #expect(session.keyPath == nil)
        #expect(session.jumpHostId == nil)
        #expect(session.startupCommand == nil)
        #expect(session.icon == nil)
        #expect(session.colorHex == nil)
        #expect(session.lastConnectedAt == nil)
        #expect(session.groupId == nil)
    }
}
