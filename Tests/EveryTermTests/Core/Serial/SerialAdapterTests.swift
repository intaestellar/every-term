import Testing
import Foundation
@testable import EveryTerm

@Suite("SerialAdapter Tests")
struct SerialAdapterTests {

    // MARK: - [쉬움] 기본 생성

    @Test("SerialAdapter 생성 후 state == .disconnected")
    @MainActor func initialState_isDisconnected() async {
        let config = SerialSessionConfig(sessionId: UUID())
        config.devicePath = "/dev/tty.nonexistent-xyz"
        let adapter = SerialAdapter(config: config)

        let state = await adapter.state
        if case .disconnected = state {
            // ok
        } else {
            Issue.record("초기 상태는 .disconnected여야 한다 (actual: \(state))")
        }
    }

    @Test("서로 다른 SerialAdapter 인스턴스는 서로 다른 id")
    @MainActor func idUniqueness() async {
        let c1 = SerialSessionConfig(sessionId: UUID())
        let c2 = SerialSessionConfig(sessionId: UUID())
        let a1 = SerialAdapter(config: c1)
        let a2 = SerialAdapter(config: c2)
        #expect(a1.id != a2.id)
    }

    @Test("RemoteConnection 프로토콜 준수 컴파일 확인")
    @MainActor func conformsToRemoteConnection() {
        let config = SerialSessionConfig(sessionId: UUID())
        let adapter: any RemoteConnection = SerialAdapter(config: config)
        #expect(adapter.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }

    // MARK: - [보통] 존재하지 않는 포트 / 안전한 disconnect

    @Test("존재하지 않는 devicePath connect() → throw + .failed 상태")
    @MainActor func nonexistentDevicePath_failsConnection() async {
        let config = SerialSessionConfig(sessionId: UUID())
        config.devicePath = "/dev/tty.nonexistent-xyz-\(UUID().uuidString)"
        let adapter = SerialAdapter(config: config)

        do {
            try await adapter.connect()
            Issue.record("연결이 실패해야 하는데 성공했다")
        } catch {
            // expected
        }

        let state = await adapter.state
        switch state {
        case .failed, .disconnected:
            break
        default:
            Issue.record("상태는 .failed 또는 .disconnected 여야 한다 (actual: \(state))")
        }
    }

    @Test("disconnect() (연결 전) 호출 시 crash 없음 (no-op 안전성)")
    @MainActor func disconnect_beforeConnect_isSafe() async {
        let config = SerialSessionConfig(sessionId: UUID())
        let adapter = SerialAdapter(config: config)
        await adapter.disconnect()

        let state = await adapter.state
        if case .disconnected = state {
            // ok
        } else {
            Issue.record("disconnect() 후 상태는 .disconnected 여야 한다 (actual: \(state))")
        }
    }

    @Test("허용되지 않은 baudRate 설정 후 connect() → throw")
    @MainActor func invalidBaudRate_causesConnectFailure() async {
        let config = SerialSessionConfig(sessionId: UUID())
        config.devicePath = "/dev/tty.whatever"
        config.baudRate = 12345 // 허용되지 않는 값

        let adapter = SerialAdapter(config: config)
        do {
            try await adapter.connect()
            Issue.record("허용되지 않은 baudRate에서 connect 는 실패해야 한다")
        } catch {
            // expected
        }
    }

    // MARK: - [어려움] FIX-3: devicePath 허용 prefix 화이트리스트

    @Test("허용되지 않은 devicePath (/etc/passwd) → connect() throw invalidConfiguration")
    @MainActor func disallowedDevicePath_throwsInvalidConfiguration() async {
        let config = SerialSessionConfig(sessionId: UUID())
        config.devicePath = "/etc/passwd"
        let adapter = SerialAdapter(config: config)
        do {
            try await adapter.connect()
            Issue.record("허용되지 않은 devicePath 에 대해 throw 되어야 한다")
        } catch let err as SerialConnectionError {
            if case .invalidConfiguration = err {
                // ok
            } else {
                Issue.record("invalidConfiguration 이어야 하는데 \(err)")
            }
        } catch {
            Issue.record("SerialConnectionError 여야 하는데 \(error)")
        }
    }

    @Test("허용된 prefix(/dev/tty.*) 는 검증 통과 (open 실패와 별개)")
    @MainActor func allowedDevicePath_passesValidation() async {
        // 검증 함수 직접 확인
        #expect(SerialAdapter.isValidDevicePath("/dev/tty.usb-xyz"))
        #expect(SerialAdapter.isValidDevicePath("/dev/cu.usbserial-1"))
        #expect(SerialAdapter.isValidDevicePath("/dev/ttyS0"))
        #expect(SerialAdapter.isValidDevicePath("/dev/ttyUSB0"))
        #expect(!SerialAdapter.isValidDevicePath("/etc/passwd"))
        #expect(!SerialAdapter.isValidDevicePath("/Users/me/.ssh/id_rsa"))
        #expect(!SerialAdapter.isValidDevicePath("/dev/random"))
    }
}
