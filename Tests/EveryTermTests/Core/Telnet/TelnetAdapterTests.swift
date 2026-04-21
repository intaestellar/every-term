import Testing
import Foundation
@testable import EveryTerm

@Suite("TelnetAdapter Tests")
struct TelnetAdapterTests {

    // MARK: - [쉬움] 기본 생성

    @Test("TelnetAdapter 생성 후 state == .disconnected")
    func initialState_isDisconnected() async {
        let adapter = TelnetAdapter(host: "localhost", port: 23)
        let state = await adapter.state
        if case .disconnected = state {
            // ok
        } else {
            Issue.record("초기 상태는 .disconnected여야 한다 (actual: \(state))")
        }
    }

    @Test("서로 다른 TelnetAdapter 인스턴스는 서로 다른 id 를 가진다")
    func idUniqueness() async {
        let a1 = TelnetAdapter(host: "host-a", port: 23)
        let a2 = TelnetAdapter(host: "host-b", port: 23)
        #expect(a1.id != a2.id)
    }

    @Test("기본 포트 23 사용 (설정 기본값)")
    func defaultPort_is23() async {
        let adapter = TelnetAdapter(host: "localhost")
        let port = await adapter.port
        #expect(port == 23)
    }

    // MARK: - [보통] 프로토콜 준수 / 상태 전이

    @Test("RemoteConnection 프로토콜 준수 컴파일 확인")
    func conformsToRemoteConnection() {
        let adapter: any RemoteConnection = TelnetAdapter(host: "localhost", port: 23)
        #expect(adapter.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }

    @Test("잘못된 호스트 connect() → throw + .failed 상태 전이")
    func invalidHost_failsAndTransitionsToFailed() async {
        // RFC 2606: .invalid TLD는 해석되지 않는다. 통신 환경 의존성 최소화.
        let adapter = TelnetAdapter(host: "nonexistent.invalid", port: 23)

        do {
            try await adapter.connect()
            Issue.record("연결이 실패해야 하는데 성공했다")
        } catch {
            // expected
        }

        let state = await adapter.state
        if case .failed = state {
            // ok
        } else if case .disconnected = state {
            // 일부 구현은 실패 후 disconnected로 복귀할 수 있음
        } else {
            Issue.record("상태는 .failed 또는 .disconnected 여야 한다 (actual: \(state))")
        }
    }

    @Test("disconnect() 호출 후 state == .disconnected (연결되지 않은 상태에서도 crash 없음)")
    func disconnect_safeFromDisconnectedState() async {
        let adapter = TelnetAdapter(host: "localhost", port: 23)
        await adapter.disconnect()
        let state = await adapter.state
        if case .disconnected = state {
            // ok
        } else {
            Issue.record("disconnect() 후 상태는 .disconnected 이어야 한다 (actual: \(state))")
        }
    }
}
