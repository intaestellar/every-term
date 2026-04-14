import Testing
import Foundation
@testable import EveryTerm

@Suite("TerminalBufferManager Tests")
struct TerminalBufferManagerTests {

    // MARK: - [쉬움] 기본 설정

    @Test("기본 탭당 상한: 10,000줄")
    func defaultPerTabLimit() {
        let manager = TerminalBufferManager()
        #expect(manager.perTabLineLimit == 10_000)
    }

    @Test("기본 앱 전체 메모리 상한: 200MB")
    func defaultAppMemoryLimit() {
        let manager = TerminalBufferManager()
        #expect(manager.appMemoryLimitBytes == 200 * 1024 * 1024)
    }

    @Test("비활성 탭 하한: 1,000줄")
    func defaultInactiveTabMinimum() {
        let manager = TerminalBufferManager()
        #expect(manager.inactiveTabMinLines == 1_000)
    }

    @Test("커스텀 설정 초기화 확인")
    func customConfiguration() {
        let manager = TerminalBufferManager(
            perTabLineLimit: 5_000,
            appMemoryLimitBytes: 100 * 1024 * 1024,
            inactiveTabMinLines: 500
        )
        #expect(manager.perTabLineLimit == 5_000)
        #expect(manager.appMemoryLimitBytes == 100 * 1024 * 1024)
        #expect(manager.inactiveTabMinLines == 500)
    }

    // MARK: - [보통] 탭당 버퍼 상한

    @Test("상한 미만 데이터 추가: 전체 보존")
    func belowLimitPreservesAllLines() {
        let manager = TerminalBufferManager(perTabLineLimit: 100)
        let tabId = UUID()

        for i in 0..<50 {
            manager.appendLine("Line \(i)", toTab: tabId)
        }

        #expect(manager.lineCount(forTab: tabId) == 50)
    }

    @Test("상한 초과 데이터 추가: 오래된 줄 제거 (FIFO)")
    func aboveLimitRemovesOldLines() {
        let manager = TerminalBufferManager(perTabLineLimit: 10)
        let tabId = UUID()

        for i in 0..<15 {
            manager.appendLine("Line \(i)", toTab: tabId)
        }

        #expect(manager.lineCount(forTab: tabId) == 10)
        // 가장 오래된 줄 (0~4)은 제거, 5~14만 남아야 함
        let firstLine = manager.line(at: 0, forTab: tabId)
        #expect(firstLine == "Line 5")
    }

    @Test("정확히 상한만큼 데이터: 경계값 테스트")
    func exactlyAtLimit() {
        let manager = TerminalBufferManager(perTabLineLimit: 10)
        let tabId = UUID()

        for i in 0..<10 {
            manager.appendLine("Line \(i)", toTab: tabId)
        }

        #expect(manager.lineCount(forTab: tabId) == 10)
    }

    // MARK: - [어려움] LRU 축소 동작

    @Test("전체 메모리 상한 도달 시 비활성 탭 버퍼 축소")
    func lruShrinkOnMemoryPressure() {
        let manager = TerminalBufferManager(
            perTabLineLimit: 10_000,
            appMemoryLimitBytes: 1024, // 아주 낮은 상한
            inactiveTabMinLines: 100
        )

        let activeTab = UUID()
        let inactiveTab = UUID()

        // 비활성 탭에 많은 데이터 추가
        for i in 0..<5_000 {
            manager.appendLine("Inactive \(i)", toTab: inactiveTab)
        }

        // 활성 탭 설정
        manager.setActiveTab(activeTab)

        // 메모리 압박 트리거
        manager.checkMemoryPressure()

        // 비활성 탭이 하한으로 축소되어야 함
        #expect(manager.lineCount(forTab: inactiveTab) <= 100)
    }

    @Test("LRU 순서: 가장 오래 비활성된 탭부터 축소")
    func lruOrderOldestFirst() {
        let manager = TerminalBufferManager(
            perTabLineLimit: 10_000,
            appMemoryLimitBytes: 1024,
            inactiveTabMinLines: 100
        )

        let tab1 = UUID()
        let tab2 = UUID()
        let tab3 = UUID()

        for i in 0..<3_000 {
            manager.appendLine("Tab1 \(i)", toTab: tab1)
            manager.appendLine("Tab2 \(i)", toTab: tab2)
            manager.appendLine("Tab3 \(i)", toTab: tab3)
        }

        // tab3이 가장 최근 활성, tab1이 가장 오래 비활성
        manager.markAccessed(tab: tab1)
        manager.markAccessed(tab: tab2)
        manager.markAccessed(tab: tab3)
        manager.setActiveTab(tab3)

        manager.checkMemoryPressure()

        // tab1이 먼저 축소되어야 함
        #expect(manager.lineCount(forTab: tab1) <= manager.lineCount(forTab: tab2))
    }

    @Test("활성 탭은 축소하지 않음")
    func activeTabNotShrunk() {
        let manager = TerminalBufferManager(
            perTabLineLimit: 10_000,
            appMemoryLimitBytes: 1024,
            inactiveTabMinLines: 100
        )

        let activeTab = UUID()

        for i in 0..<5_000 {
            manager.appendLine("Active \(i)", toTab: activeTab)
        }

        manager.setActiveTab(activeTab)
        manager.checkMemoryPressure()

        // 활성 탭은 축소되지 않아야 함
        #expect(manager.lineCount(forTab: activeTab) == 5_000)
    }

    @Test("모든 탭이 하한인 상태에서 추가 메모리 압박 시 안전 동작")
    func allTabsAtMinimumSafetyCheck() {
        let manager = TerminalBufferManager(
            perTabLineLimit: 10_000,
            appMemoryLimitBytes: 1,
            inactiveTabMinLines: 100
        )

        let tab = UUID()
        for i in 0..<100 {
            manager.appendLine("Line \(i)", toTab: tab)
        }

        // 이미 하한 — checkMemoryPressure가 크래시 없이 동작해야 함
        manager.checkMemoryPressure()
        #expect(manager.lineCount(forTab: tab) >= 0)
    }
}
