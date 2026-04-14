import Testing
import Foundation
@testable import EveryTerm

@Suite("SessionGroup Model Tests")
struct SessionGroupTests {

    @Test("필수 필드로 SessionGroup 생성 후 프로퍼티 일치 확인")
    @MainActor func createSessionGroup() {
        let group = SessionGroup(name: "Production Servers")
        #expect(group.name == "Production Servers")
        #expect(group.id != UUID())
    }

    @Test("parentId nil 시 루트 그룹 확인")
    @MainActor func rootGroup() {
        let group = SessionGroup(name: "Root")
        #expect(group.parentId == nil)
    }

    @Test("isExpanded 기본값 확인")
    @MainActor func defaultIsExpanded() {
        let group = SessionGroup(name: "Group")
        #expect(group.isExpanded == true)
    }

    @Test("sortOrder 기본값 확인")
    @MainActor func defaultSortOrder() {
        let group = SessionGroup(name: "Group")
        #expect(group.sortOrder == 0)
    }

    @Test("parentId 설정하여 하위 그룹 생성")
    @MainActor func childGroup() {
        let parentId = UUID()
        let child = SessionGroup(name: "Child", parentId: parentId)
        #expect(child.parentId == parentId)
    }
}
