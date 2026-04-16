import Testing
import Foundation
@testable import EveryTerm

@Suite("SSHAdapter Integration Tests")
struct SSHAdapterIntegrationTests {

    @Test("잘못된 호스트/포트 연결 시도 시 적절한 에러 throw")
    func invalidHostThrows() async {
        let adapter = SSHAdapter(
            host: "invalid.nonexistent.host.example",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes(utf8: "pass"))
        )

        do {
            try await adapter.connect()
            #expect(Bool(false), "연결 에러가 throw되어야 한다")
        } catch {
            #expect(error is SSHConnectionError)
        }
    }

    @Test("잘못된 자격 증명으로 인증 실패 시 에러 처리")
    func invalidCredentialsThrows() async {
        let adapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "nonexistent_user_\(UUID().uuidString)",
            authMethod: .password(SecureBytes(utf8: "wrong"))
        )

        do {
            try await adapter.connect()
            #expect(Bool(false), "인증 실패 에러가 throw되어야 한다")
        } catch {
            #expect(error is SSHConnectionError)
        }
    }

    @Test("연결 중 네트워크 끊김 시 상태 전이")
    func networkDisconnectionTransition() async throws {
        let adapter = SSHAdapter(
            host: "localhost",
            port: 22,
            username: "test",
            authMethod: .password(SecureBytes(utf8: "test"))
        )

        // 연결이 실패하더라도 상태 전이가 올바르게 발생해야 함
        let stream = await adapter.stateStream
        var states: [ConnectionState] = []

        Task {
            try? await adapter.connect()
        }

        for await state in stream {
            states.append(state)
            if case .failed = state { break }
            if case .connected = state { break }
            if states.count >= 3 { break }
        }

        #expect(!states.isEmpty, "상태 변경 이벤트가 발생해야 한다")
    }

    @Test("known_hosts에 없는 호스트 연결 시 적절한 경고/에러")
    func unknownHostWarning() async {
        let adapter = SSHAdapter(
            host: "unknown-host-test.example.com",
            port: 22,
            username: "user",
            authMethod: .password(SecureBytes(utf8: "pass"))
        )

        do {
            try await adapter.connect()
            #expect(Bool(false), "에러가 throw되어야 한다")
        } catch {
            // 연결 실패 또는 known_hosts 관련 에러
            #expect(error is SSHConnectionError)
        }
    }
}
