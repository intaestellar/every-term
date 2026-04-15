import Testing
import Foundation
@testable import EveryTerm

@Suite("TerminalBufferManager Tests")
struct TerminalBufferManagerTests {

    // MARK: - [쉬움] 기본 설정

    @Test("기본 탭당 상한: 10,000줄")
    func defaultPerTabLimit() async {
        let manager = TerminalBufferManager()
        let limit = await manager.perTabLineLimit
        #expect(limit == 10_000)
    }

    @Test("기본 앱 전체 메모리 상한: 200MB")
    func defaultAppMemoryLimit() async {
        let manager = TerminalBufferManager()
        let limit = await manager.appMemoryLimitBytes
        #expect(limit == 200 * 1024 * 1024)
    }

    @Test("비활성 탭 하한: 1,000줄")
    func defaultInactiveTabMinimum() async {
        let manager = TerminalBufferManager()
        let limit = await manager.inactiveTabMinLines
        #expect(limit == 1_000)
    }

    @Test("커스텀 설정 초기화 확인")
    func customConfiguration() async {
        let manager = TerminalBufferManager(
            perTabLineLimit: 5_000,
            appMemoryLimitBytes: 100 * 1024 * 1024,
            inactiveTabMinLines: 500
        )
        let perTab = await manager.perTabLineLimit
        let appMem = await manager.appMemoryLimitBytes
        let inactiveMin = await manager.inactiveTabMinLines
        #expect(perTab == 5_000)
        #expect(appMem == 100 * 1024 * 1024)
        #expect(inactiveMin == 500)
    }

    // MARK: - [보통] 탭당 버퍼 상한

    @Test("상한 미만 데이터 추가: 전체 보존")
    func belowLimitPreservesAllLines() async {
        let manager = TerminalBufferManager(perTabLineLimit: 100)
        let tabId = UUID()

        for i in 0..<50 {
            await manager.appendLine("Line \(i)", toTab: tabId)
        }

        let count = await manager.lineCount(forTab: tabId)
        #expect(count == 50)
    }

    @Test("상한 초과 데이터 추가: 오래된 줄 제거 (FIFO)")
    func aboveLimitRemovesOldLines() async {
        let manager = TerminalBufferManager(perTabLineLimit: 10)
        let tabId = UUID()

        for i in 0..<15 {
            await manager.appendLine("Line \(i)", toTab: tabId)
        }

        let count = await manager.lineCount(forTab: tabId)
        #expect(count == 10)
        // 가장 오래된 줄 (0~4)은 제거, 5~14만 남아야 함
        let firstLine = await manager.line(at: 0, forTab: tabId)
        #expect(firstLine == "Line 5")
    }

    @Test("정확히 상한만큼 데이터: 경계값 테스트")
    func exactlyAtLimit() async {
        let manager = TerminalBufferManager(perTabLineLimit: 10)
        let tabId = UUID()

        for i in 0..<10 {
            await manager.appendLine("Line \(i)", toTab: tabId)
        }

        let count = await manager.lineCount(forTab: tabId)
        #expect(count == 10)
    }

    // MARK: - [어려움] LRU 축소 동작

    @Test("전체 메모리 상한 도달 시 비활성 탭 버퍼 축소")
    func lruShrinkOnMemoryPressure() async {
        let manager = TerminalBufferManager(
            perTabLineLimit: 10_000,
            appMemoryLimitBytes: 1024, // 아주 낮은 상한
            inactiveTabMinLines: 100
        )

        let activeTab = UUID()
        let inactiveTab = UUID()

        // 비활성 탭에 많은 데이터 추가
        for i in 0..<5_000 {
            await manager.appendLine("Inactive \(i)", toTab: inactiveTab)
        }

        // 활성 탭 설정
        await manager.setActiveTab(activeTab)

        // 메모리 압박 트리거
        await manager.checkMemoryPressure()

        // 비활성 탭이 하한으로 축소되어야 함
        let count = await manager.lineCount(forTab: inactiveTab)
        #expect(count <= 100)
    }

    @Test("LRU 순서: 가장 오래 비활성된 탭부터 축소")
    func lruOrderOldestFirst() async {
        let manager = TerminalBufferManager(
            perTabLineLimit: 10_000,
            appMemoryLimitBytes: 1024,
            inactiveTabMinLines: 100
        )

        let tab1 = UUID()
        let tab2 = UUID()
        let tab3 = UUID()

        for i in 0..<3_000 {
            await manager.appendLine("Tab1 \(i)", toTab: tab1)
            await manager.appendLine("Tab2 \(i)", toTab: tab2)
            await manager.appendLine("Tab3 \(i)", toTab: tab3)
        }

        // tab3이 가장 최근 활성, tab1이 가장 오래 비활성
        await manager.markAccessed(tab: tab1)
        await manager.markAccessed(tab: tab2)
        await manager.markAccessed(tab: tab3)
        await manager.setActiveTab(tab3)

        await manager.checkMemoryPressure()

        // tab1이 먼저 축소되어야 함
        let count1 = await manager.lineCount(forTab: tab1)
        let count2 = await manager.lineCount(forTab: tab2)
        #expect(count1 <= count2)
    }

    @Test("활성 탭은 축소하지 않음")
    func activeTabNotShrunk() async {
        let manager = TerminalBufferManager(
            perTabLineLimit: 10_000,
            appMemoryLimitBytes: 1024,
            inactiveTabMinLines: 100
        )

        let activeTab = UUID()

        for i in 0..<5_000 {
            await manager.appendLine("Active \(i)", toTab: activeTab)
        }

        await manager.setActiveTab(activeTab)
        await manager.checkMemoryPressure()

        // 활성 탭은 축소되지 않아야 함
        let count = await manager.lineCount(forTab: activeTab)
        #expect(count == 5_000)
    }

    @Test("모든 탭이 하한인 상태에서 추가 메모리 압박 시 안전 동작")
    func allTabsAtMinimumSafetyCheck() async {
        let manager = TerminalBufferManager(
            perTabLineLimit: 10_000,
            appMemoryLimitBytes: 1,
            inactiveTabMinLines: 100
        )

        let tab = UUID()
        for i in 0..<100 {
            await manager.appendLine("Line \(i)", toTab: tab)
        }

        // 이미 하한 — checkMemoryPressure가 크래시 없이 동작해야 함
        await manager.checkMemoryPressure()
        let count = await manager.lineCount(forTab: tab)
        #expect(count >= 0)
    }
}
