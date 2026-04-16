import Testing
import Foundation
@testable import EveryTerm

@Suite("TabItem Tests")
struct TabItemTests {

    @Test("TabItem 생성 후 id, title 확인")
    func createTabItem() {
        let item = TabItem(title: "Local Shell")
        #expect(item.title == "Local Shell")
        #expect(item.id != UUID())
    }

    @Test("splitLayout 기본값 확인")
    func defaultSplitLayout() {
        let item = TabItem(title: "Test")
        #expect(item.splitLayout == .single)
    }
}
