import Testing
import Foundation
@testable import EveryTerm

@Suite("MenuBarViewModel Tests")
@MainActor
struct MenuBarBadgeLogicTests {

    // MARK: - [쉬움] 초기 상태

    @Test("초기 상태: connectedSessionCount == 0, badgeText == nil")
    func initialState() {
        let vm = MenuBarViewModel()
        #expect(vm.connectedSessionCount == 0)
        #expect(vm.badgeText == nil)
    }

    @Test("isMenuBarEnabled 기본값 true")
    func defaultEnabled() {
        let vm = MenuBarViewModel()
        #expect(vm.isMenuBarEnabled == true)
    }

    // MARK: - [보통] 배지 표시

    @Test("연결된 세션 2개 → badgeText == \"2\"")
    func badgeCountTwo() {
        let vm = MenuBarViewModel()
        vm.updateConnectedCount(2)
        #expect(vm.badgeText == "2")
    }

    @Test("연결된 세션 0개 → badgeText == nil (숨김)")
    func badgeZeroHidden() {
        let vm = MenuBarViewModel()
        vm.updateConnectedCount(5)
        vm.updateConnectedCount(0)
        #expect(vm.badgeText == nil)
    }

    @Test("9개 이하 숫자, 10개 이상 '9+'")
    func badgeBoundary() {
        let vm = MenuBarViewModel()
        vm.updateConnectedCount(9)
        #expect(vm.badgeText == "9")
        vm.updateConnectedCount(10)
        #expect(vm.badgeText == "9+")
        vm.updateConnectedCount(100)
        #expect(vm.badgeText == "9+")
    }

    @Test("quickConnectItems — 저장된 세션 상위 5개만 노출")
    func quickConnectTopFive() {
        let now = Date()
        let sessions = (0..<8).map { i in
            Session(
                name: "S\(i)",
                type: .ssh,
                host: "h",
                username: "u",
                authMethod: .password,
                lastConnectedAt: now.addingTimeInterval(TimeInterval(-i))
            )
        }
        let vm = MenuBarViewModel()
        vm.setSessions(sessions)
        #expect(vm.quickConnectItems.count == 5)
    }

    @Test("quickConnectItems 각 항목 선택 콜백에 세션 ID 전달")
    func quickConnectCallbackDeliversId() {
        let s = Session(name: "S", type: .ssh, host: "h", username: "u", authMethod: .password)
        var received: UUID?
        let vm = MenuBarViewModel(onSelectSession: { id in
            received = id
        })
        vm.setSessions([s])
        vm.activateQuickConnect(at: 0)
        #expect(received == s.id)
    }
}
