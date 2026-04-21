import Testing
import Foundation
@testable import EveryTerm

@Suite("UnsafeProtocolWarningViewModel Tests")
@MainActor
struct InsecureProtocolWarningTests {

    // MARK: - [쉬움] 표시 조건

    @Test("Telnet + 경고무시 false → shouldPresentAlert == true")
    func telnetShowsAlert() {
        let s = Session(name: "t", type: .telnet, host: "h", username: "u", authMethod: .password)
        let storage = MockWarningStorage()
        let vm = UnsafeProtocolWarningViewModel(session: s, storage: storage)
        #expect(vm.shouldPresentAlert == true)
    }

    @Test("SSH 세션 → shouldPresentAlert == false")
    func sshNoAlert() {
        let s = Session(name: "s", type: .ssh, host: "h", username: "u", authMethod: .password)
        let storage = MockWarningStorage()
        let vm = UnsafeProtocolWarningViewModel(session: s, storage: storage)
        #expect(vm.shouldPresentAlert == false)
    }

    @Test("Telnet + 경고무시 true → shouldPresentAlert == false")
    func telnetIgnoredNoAlert() {
        let s = Session(name: "t", type: .telnet, host: "h", username: "u", authMethod: .password)
        let storage = MockWarningStorage()
        storage.setIgnored(true, for: s.id)
        let vm = UnsafeProtocolWarningViewModel(session: s, storage: storage)
        #expect(vm.shouldPresentAlert == false)
    }

    @Test("VNC + sshTunnelSessionId == nil + 무시 false → shouldPresentAlert == true")
    func vncWithoutTunnelShowsAlert() {
        let s = Session(name: "v", type: .vnc, host: "h", username: "u", authMethod: .password)
        let storage = MockWarningStorage()
        let vm = UnsafeProtocolWarningViewModel(session: s, storage: storage, vncSshTunnelSessionId: nil)
        #expect(vm.shouldPresentAlert == true)
    }

    @Test("VNC + sshTunnelSessionId != nil → shouldPresentAlert == false")
    func vncWithTunnelNoAlert() {
        let s = Session(name: "v", type: .vnc, host: "h", username: "u", authMethod: .password)
        let storage = MockWarningStorage()
        let vm = UnsafeProtocolWarningViewModel(session: s, storage: storage, vncSshTunnelSessionId: UUID())
        #expect(vm.shouldPresentAlert == false)
    }

    // MARK: - [보통] 메시지 / 버튼

    @Test("alertTitle 문자열에 '암호화' 키워드 포함")
    func alertTitleContainsKeyword() {
        let s = Session(name: "t", type: .telnet, host: "h", username: "u", authMethod: .password)
        let storage = MockWarningStorage()
        let vm = UnsafeProtocolWarningViewModel(session: s, storage: storage)
        #expect(vm.alertTitle.contains("암호화"))
    }

    @Test("alertButtons 에 '이해하고 계속' + '취소' 2개 존재")
    func alertButtonsContent() {
        let s = Session(name: "t", type: .telnet, host: "h", username: "u", authMethod: .password)
        let storage = MockWarningStorage()
        let vm = UnsafeProtocolWarningViewModel(session: s, storage: storage)
        let titles = vm.alertButtons.map(\.title)
        #expect(titles.contains("이해하고 계속"))
        #expect(titles.contains("취소"))
    }

    @Test("'이해하고 계속' 선택 시 콜백에 AcknowledgeAction.proceed")
    func proceedCallback() {
        let s = Session(name: "t", type: .telnet, host: "h", username: "u", authMethod: .password)
        let storage = MockWarningStorage()
        var received: AcknowledgeAction?
        let vm = UnsafeProtocolWarningViewModel(session: s, storage: storage) { action in
            received = action
        }
        vm.handleProceed()
        #expect(received == .proceed)
    }

    @Test("'취소' 선택 시 콜백에 .cancel")
    func cancelCallback() {
        let s = Session(name: "t", type: .telnet, host: "h", username: "u", authMethod: .password)
        let storage = MockWarningStorage()
        var received: AcknowledgeAction?
        let vm = UnsafeProtocolWarningViewModel(session: s, storage: storage) { action in
            received = action
        }
        vm.handleCancel()
        #expect(received == .cancel)
    }

    @Test("markIgnored(for:) 호출 시 Storage 키(ignoreUnsafeWarning.<sessionId>) 갱신")
    func markIgnoredUpdatesStorage() {
        let s = Session(name: "t", type: .telnet, host: "h", username: "u", authMethod: .password)
        let storage = MockWarningStorage()
        let vm = UnsafeProtocolWarningViewModel(session: s, storage: storage)
        vm.markIgnored()
        #expect(storage.isIgnored(for: s.id) == true)
    }

    @Test("세션별 무시 플래그 독립성 (교차 간섭 없음)")
    func independentPerSession() {
        let a = Session(name: "a", type: .telnet, host: "h", username: "u", authMethod: .password)
        let b = Session(name: "b", type: .telnet, host: "h", username: "u", authMethod: .password)
        let storage = MockWarningStorage()
        storage.setIgnored(true, for: a.id)
        #expect(storage.isIgnored(for: a.id) == true)
        #expect(storage.isIgnored(for: b.id) == false)
    }
}

// MARK: - Mock Storage

@MainActor
final class MockWarningStorage: UnsafeWarningStorage {
    private var ignored: [UUID: Bool] = [:]

    func isIgnored(for sessionId: UUID) -> Bool {
        ignored[sessionId] ?? false
    }

    func setIgnored(_ value: Bool, for sessionId: UUID) {
        ignored[sessionId] = value
    }
}
