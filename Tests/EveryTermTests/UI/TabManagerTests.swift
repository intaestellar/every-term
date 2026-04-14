import Testing
import Foundation
@testable import EveryTerm

@Suite("TabManager Tests")
struct TabManagerTests {

    @Test("탭 추가 후 목록에 포함 확인")
    @MainActor func addTab() {
        let manager = TabManager()
        let tab = TabItem(title: "New Tab")
        manager.addTab(tab)

        #expect(manager.tabs.contains(where: { $0.id == tab.id }))
    }

    @Test("탭 제거 후 목록에서 제거 확인")
    @MainActor func removeTab() {
        let manager = TabManager()
        let tab = TabItem(title: "To Remove")
        manager.addTab(tab)
        manager.removeTab(tab.id)

        #expect(!manager.tabs.contains(where: { $0.id == tab.id }))
    }

    @Test("활성 탭 전환 동작")
    @MainActor func switchActiveTab() {
        let manager = TabManager()
        let tab1 = TabItem(title: "Tab 1")
        let tab2 = TabItem(title: "Tab 2")
        manager.addTab(tab1)
        manager.addTab(tab2)

        manager.setActiveTab(tab2.id)
        #expect(manager.activeTabId == tab2.id)

        manager.setActiveTab(tab1.id)
        #expect(manager.activeTabId == tab1.id)
    }

    @Test("탭 순서 변경 (드래그)")
    @MainActor func reorderTabs() {
        let manager = TabManager()
        let tab1 = TabItem(title: "First")
        let tab2 = TabItem(title: "Second")
        let tab3 = TabItem(title: "Third")
        manager.addTab(tab1)
        manager.addTab(tab2)
        manager.addTab(tab3)

        manager.moveTab(from: 0, to: 2)

        #expect(manager.tabs[0].id == tab2.id)
        #expect(manager.tabs[1].id == tab3.id)
        #expect(manager.tabs[2].id == tab1.id)
    }

    @Test("빈 탭 목록에서 제거 시도 시 안전 동작")
    @MainActor func removeFromEmptyList() {
        let manager = TabManager()
        // 크래시 없이 동작해야 함
        manager.removeTab(UUID())
        #expect(manager.tabs.isEmpty)
    }

    @Test("탭 닫기 시 연결 상태 확인 로직")
    @MainActor func closeTabWithActiveConnection() async {
        let manager = TabManager()
        let tab = TabItem(title: "Connected Tab")
        manager.addTab(tab)

        let hasActiveConnection = await manager.hasActiveConnection(tabId: tab.id)
        // 연결이 없으면 false
        #expect(hasActiveConnection == false)
    }
}
