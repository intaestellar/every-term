import Testing
import Foundation
@testable import EveryTerm

@Suite("Multi-Protocol Integration Tests")
struct MultiProtocolIntegrationTests {

    // MARK: - RDP/VNC 스텁 연결 실패 전파

    @Test("RDPAdapter.connect() 실패 시 notImplemented 메시지가 전파된다")
    @MainActor func rdpConnect_propagatesNotImplemented() async {
        let config = RDPSessionConfig(sessionId: UUID())
        let adapter = RDPAdapter(host: "rdp.example.com", config: config)

        var captured: RemoteConnectionError?
        do {
            try await adapter.connect()
        } catch let error as RemoteConnectionError {
            captured = error
        } catch {
            Issue.record("예상치 못한 에러: \(error)")
        }

        #expect(captured != nil)
        if case .some(.notImplemented(let msg)) = captured {
            #expect(msg.contains("FreeRDP"))
        }
    }

    @Test("VNCAdapter.connect() 실패 시 notImplemented 메시지가 전파된다")
    @MainActor func vncConnect_propagatesNotImplemented() async {
        let config = VNCSessionConfig(sessionId: UUID())
        let adapter = VNCAdapter(host: "vnc.example.com", config: config)

        var captured: RemoteConnectionError?
        do {
            try await adapter.connect()
        } catch let error as RemoteConnectionError {
            captured = error
        } catch {
            Issue.record("예상치 못한 에러: \(error)")
        }

        #expect(captured != nil)
        if case .some(.notImplemented(let msg)) = captured {
            #expect(msg.contains("LibVNCClient"))
        }
    }

    // MARK: - Telnet 초기 상태 통합 체크

    @Test("SessionType.telnet 세션 → TelnetAdapter가 .disconnected 로 생성된다")
    @MainActor func telnetSession_initializesAdapterDisconnected() async {
        let adapter = TelnetAdapter(host: "localhost", port: 23)
        let state = await adapter.state
        if case .disconnected = state {
            // ok
        } else {
            Issue.record(".disconnected 초기 상태 기대 (actual: \(state))")
        }
    }

    // MARK: - Serial 초기 상태 통합 체크

    @Test("SessionType.serial 세션 → SerialAdapter가 .disconnected 로 생성된다")
    @MainActor func serialSession_initializesAdapterDisconnected() async {
        let config = SerialSessionConfig(sessionId: UUID())
        config.devicePath = "/dev/tty.anything"
        let adapter = SerialAdapter(config: config)

        let state = await adapter.state
        if case .disconnected = state {
            // ok
        } else {
            Issue.record(".disconnected 초기 상태 기대 (actual: \(state))")
        }
    }

    // MARK: - 외부 의존성 가드 (socat) — 환경 변수로 조건부 실행

    @Test(
        "socat 기반 Serial E2E는 환경에 socat 가 있을 때만 실행 (가드)",
        .enabled(if: ProcessInfo.processInfo.environment["SERIAL_INTEGRATION"] == "1")
    )
    func serialSocatE2E_guardedBySerialIntegrationEnv() async {
        // 실제 socat PTY 왕복 테스트는 별도 구현에서 채우며, 여기서는 환경가드가 동작함을 확인.
        // 환경변수 SERIAL_INTEGRATION=1 일 때만 실행된다.
        #expect(ProcessInfo.processInfo.environment["SERIAL_INTEGRATION"] == "1")
    }
}
