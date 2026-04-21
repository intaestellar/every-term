import Testing
import Foundation
@testable import EveryTerm

@Suite("CommandPaletteViewModel Tests")
@MainActor
struct CommandPaletteViewModelTests {

    private func makeItems(_ titles: [String]) -> [CommandPaletteItem] {
        titles.map { CommandPaletteItem(id: UUID(), title: $0, subtitle: nil, kind: .session) }
    }

    // MARK: - [쉬움] 초기 상태

    @Test("초기 상태: query==\"\", selectedIndex==0, filteredItems.count==items.count")
    func initialState() {
        let items = makeItems(["a", "b", "c"])
        let vm = CommandPaletteViewModel(items: items)
        #expect(vm.query == "")
        #expect(vm.selectedIndex == 0)
        #expect(vm.filteredItems.count == items.count)
    }

    @Test("isVisible 기본값 false")
    func defaultIsVisible() {
        let vm = CommandPaletteViewModel(items: [])
        #expect(vm.isVisible == false)
    }

    @Test("query 변경 시 filteredItems 갱신")
    func queryChangeUpdatesFiltered() {
        let items = makeItems(["ssh prod", "rdp dev"])
        let vm = CommandPaletteViewModel(items: items)
        vm.query = "ssh"
        #expect(vm.filteredItems.allSatisfy { $0.title.contains("ssh") })
    }

    // MARK: - [보통] 선택 / 이동

    @Test("쿼리 변경 시 selectedIndex 0으로 리셋")
    func queryChangeResetsSelectedIndex() {
        let items = makeItems(["a", "b", "c"])
        let vm = CommandPaletteViewModel(items: items)
        vm.moveSelection(.down)
        #expect(vm.selectedIndex == 1)
        vm.query = "a"
        #expect(vm.selectedIndex == 0)
    }

    @Test("moveSelection(.down) → selectedIndex +1, 범위 초과 시 마지막에 고정")
    func moveSelectionDownClamps() {
        let items = makeItems(["a", "b"])
        let vm = CommandPaletteViewModel(items: items)
        vm.moveSelection(.down)
        #expect(vm.selectedIndex == 1)
        vm.moveSelection(.down)
        #expect(vm.selectedIndex == 1) // clamped
    }

    @Test("moveSelection(.up) → selectedIndex -1, 0 아래 금지")
    func moveSelectionUpClamps() {
        let items = makeItems(["a", "b"])
        let vm = CommandPaletteViewModel(items: items)
        vm.moveSelection(.up)
        #expect(vm.selectedIndex == 0) // still 0
        vm.moveSelection(.down)
        vm.moveSelection(.up)
        #expect(vm.selectedIndex == 0)
    }

    @Test("필터 결과 빈 배열에서 moveSelection 호출 시 crash 없음")
    func moveOnEmptyNoCrash() {
        let vm = CommandPaletteViewModel(items: [])
        vm.moveSelection(.down)
        vm.moveSelection(.up)
        #expect(vm.selectedIndex == 0)
    }

    @Test("activateSelected() → 콜백에 filteredItems[selectedIndex] 전달")
    func activateSelectedInvokesCallback() {
        let items = makeItems(["a", "b", "c"])
        var received: CommandPaletteItem?
        let vm = CommandPaletteViewModel(items: items) { item in
            received = item
        }
        vm.moveSelection(.down)
        vm.activateSelected()
        #expect(received?.title == "b")
    }

    @Test("activateSelected() 후 isVisible == false")
    func activateHidesPalette() {
        let items = makeItems(["a"])
        let vm = CommandPaletteViewModel(items: items) { _ in }
        vm.isVisible = true
        vm.activateSelected()
        #expect(vm.isVisible == false)
    }

    @Test("reset() → query==\"\", selectedIndex==0, isVisible==false")
    func resetRestoresDefaults() {
        let items = makeItems(["a", "b"])
        let vm = CommandPaletteViewModel(items: items)
        vm.query = "a"
        vm.isVisible = true
        vm.moveSelection(.down)
        vm.reset()
        #expect(vm.query == "")
        #expect(vm.selectedIndex == 0)
        #expect(vm.isVisible == false)
    }
}
