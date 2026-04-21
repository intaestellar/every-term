import Testing
import Foundation
@testable import EveryTerm

@Suite("VNCAdapter Stub Tests")
struct VNCAdapterTests {

    // MARK: - [쉬움] 기본 생성 / 프로토콜 준수

    @Test("VNCAdapter 생성 후 state == .disconnected")
    @MainActor func initialState_isDisconnected() async {
        let config = VNCSessionConfig(sessionId: UUID())
        let adapter = VNCAdapter(host: "vnc.example.com", config: config)

        let state = await adapter.state
        if case .disconnected = state {
            // ok
        } else {
            Issue.record("초기 상태는 .disconnected 여야 한다 (actual: \(state))")
        }
    }

    @Test("RemoteConnection 프로토콜 준수 컴파일 확인")
    @MainActor func conformsToRemoteConnection() {
        let config = VNCSessionConfig(sessionId: UUID())
        let adapter: any RemoteConnection = VNCAdapter(host: "h", config: config)
        #expect(adapter.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }

    @Test("서로 다른 VNCAdapter 인스턴스는 서로 다른 id")
    @MainActor func idUniqueness() {
        let config = VNCSessionConfig(sessionId: UUID())
        let a1 = VNCAdapter(host: "a", config: config)
        let a2 = VNCAdapter(host: "b", config: config)
        #expect(a1.id != a2.id)
    }

    // MARK: - [보통] 스텁 계약

    @Test("connect() → RemoteConnectionError.unsupportedProtocol throw")
    @MainActor func connect_throwsUnsupportedProtocol() async {
        let config = VNCSessionConfig(sessionId: UUID())
        let adapter = VNCAdapter(host: "vnc.example.com", config: config)

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
        let config = VNCSessionConfig(sessionId: UUID())
        let adapter = VNCAdapter(host: "h", config: config)
        await adapter.disconnect()
    }

    @Test("sshTunnelSessionId 설정된 config로 초기화해도 crash 없음")
    @MainActor func initialization_withSSHTunnelId_doesNotCrash() {
        let config = VNCSessionConfig(sessionId: UUID())
        config.sshTunnelSessionId = UUID()
        _ = VNCAdapter(host: "localhost", config: config)
        // 생성이 crash 없이 끝나면 성공
    }
}
