import Testing
import Foundation
@testable import EveryTerm

@Suite("MacroEditorViewModel Tests")
struct MacroEditorViewModelTests {

    // MARK: - [쉬움] 초기 상태 / 추가

    @Test("초기 액션 목록 빈 배열 확인")
    @MainActor func initialActionsEmpty() {
        let viewModel = MacroEditorViewModel()

        #expect(viewModel.actions.isEmpty)
    }

    @Test("액션 추가 후 목록 개수 증가 확인")
    @MainActor func addActionIncreasesCount() {
        let viewModel = MacroEditorViewModel()
        viewModel.addAction(.type(text: "hello"))

        #expect(viewModel.actions.count == 1)
    }

    // MARK: - [보통] 삭제 / 순서 변경 / JSON

    @Test("액션 삭제 후 목록 개수 감소 확인")
    @MainActor func deleteActionDecreasesCount() {
        let viewModel = MacroEditorViewModel()
        viewModel.addAction(.type(text: "first"))
        viewModel.addAction(.type(text: "second"))
        viewModel.deleteAction(at: 0)

        #expect(viewModel.actions.count == 1)
    }

    @Test("액션 순서 변경 (move) 확인")
    @MainActor func moveActionReorders() {
        let viewModel = MacroEditorViewModel()
        viewModel.addAction(.type(text: "A"))
        viewModel.addAction(.type(text: "B"))
        viewModel.addAction(.type(text: "C"))

        viewModel.moveAction(from: 0, to: 2)

        if case .type(let text) = viewModel.actions[0] {
            #expect(text == "B")
        } else {
            #expect(Bool(false), "이동 후 첫 번째는 B여야 한다")
        }
    }

    @Test("JSON 내보내기 -> 유효한 JSON 문자열 반환")
    @MainActor func exportToJSON() throws {
        let viewModel = MacroEditorViewModel()
        viewModel.addAction(.type(text: "ls"))
        viewModel.addAction(.wait(seconds: 1.0))

        let jsonString = try viewModel.exportJSON()

        // JSON 파싱 가능 여부 확인
        let data = jsonString.data(using: .utf8)!
        let parsed = try JSONSerialization.jsonObject(with: data)
        #expect(parsed is [[String: Any]])
    }

    @Test("JSON 가져오기 -> 액션 목록 복원 확인")
    @MainActor func importFromJSON() throws {
        let viewModel = MacroEditorViewModel()
        viewModel.addAction(.type(text: "echo hello"))
        viewModel.addAction(.keyPress(key: "Return", modifiers: []))

        let jsonString = try viewModel.exportJSON()

        let newViewModel = MacroEditorViewModel()
        try newViewModel.importJSON(jsonString)

        #expect(newViewModel.actions.count == 2)
    }

    // MARK: - [어려움] 잘못된 JSON

    @Test("잘못된 JSON 가져오기 -> 에러 처리 확인")
    @MainActor func importInvalidJSONThrows() {
        let viewModel = MacroEditorViewModel()
        let invalidJSON = "{ this is not valid json }"

        #expect(throws: Error.self) {
            try viewModel.importJSON(invalidJSON)
        }
    }
}
