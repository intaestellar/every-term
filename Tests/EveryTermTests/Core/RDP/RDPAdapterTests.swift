import Testing
import Foundation
@testable import EveryTerm

@Suite("RDPAdapter Stub Tests")
struct RDPAdapterTests {

    // MARK: - [쉬움] 기본 생성 / 프로토콜 준수

    @Test("RDPAdapter 생성 후 state == .disconnected")
    @MainActor func initialState_isDisconnected() async {
        let config = RDPSessionConfig(sessionId: UUID())
        let adapter = RDPAdapter(host: "rdp.example.com", config: config)

        let state = await adapter.state
        if case .disconnected = state {
            // ok
        } else {
            Issue.record("초기 상태는 .disconnected 여야 한다 (actual: \(state))")
        }
    }

    @Test("RemoteConnection 프로토콜 준수 컴파일 확인")
    @MainActor func conformsToRemoteConnection() {
        let config = RDPSessionConfig(sessionId: UUID())
        let adapter: any RemoteConnection = RDPAdapter(host: "h", config: config)
        #expect(adapter.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }

    @Test("서로 다른 RDPAdapter 인스턴스는 서로 다른 id")
    @MainActor func idUniqueness() {
        let config = RDPSessionConfig(sessionId: UUID())
        let a1 = RDPAdapter(host: "a", config: config)
        let a2 = RDPAdapter(host: "b", config: config)
        #expect(a1.id != a2.id)
    }

    // MARK: - [보통] 스텁 계약

    @Test("connect() 호출 시 RemoteConnectionError.unsupportedProtocol throw")
    @MainActor func connect_throwsUnsupportedProtocol() async {
        let config = RDPSessionConfig(sessionId: UUID())
        let adapter = RDPAdapter(host: "rdp.example.com", config: config)

        do {
            try await adapter.connect()
            Issue.record("connect()가 throw 해야 한다")
        } catch let error as RemoteConnectionError {
            switch error {
            case .unsupportedProtocol:
                break // 성공
            default:
                Issue.record(".unsupportedProtocol 이 예상되지만 \(error) 가 발생")
            }
        } catch {
            Issue.record("RemoteConnectionError.unsupportedProtocol 이 예상되지만 \(error) 가 발생")
        }
    }

    @Test("disconnect() 호출 시 crash 없음 (no-op)")
    @MainActor func disconnect_isSafeNoOp() async {
        let config = RDPSessionConfig(sessionId: UUID())
        let adapter = RDPAdapter(host: "h", config: config)
        await adapter.disconnect()
        // crash 없이 반환하면 성공
    }

    @Test("RemoteConnectionError.notImplemented(메시지) 케이스 존재 / 메시지 필드 접근")
    func remoteConnectionError_notImplementedHasMessage() {
        let err = RemoteConnectionError.notImplemented("hello")
        switch err {
        case .notImplemented(let msg):
            #expect(msg == "hello")
        default:
            Issue.record("notImplemented case가 매칭되어야 한다")
        }
    }
}
