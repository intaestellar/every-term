import Testing
import Foundation
@testable import EveryTerm

@Suite("MacroRecorder Tests")
struct MacroRecorderTests {

    // MARK: - [쉬움] 초기 상태 / 녹화 전환

    @Test("MacroRecorder 생성 후 isRecording=false 확인")
    func initialNotRecording() async {
        let recorder = MacroRecorder()
        let recording = await recorder.isRecording

        #expect(recording == false)
    }

    @Test("녹화 시작 -> isRecording=true 전이")
    func startRecordingTransition() async {
        let recorder = MacroRecorder()
        await recorder.startRecording()
        let recording = await recorder.isRecording

        #expect(recording == true)
    }

    @Test("녹화 중지 -> isRecording=false 전이 + [MacroAction] 반환")
    func stopRecordingReturnsActions() async {
        let recorder = MacroRecorder()
        await recorder.startRecording()
        let actions = await recorder.stopRecording()

        let recording = await recorder.isRecording
        #expect(recording == false)
        #expect(actions is [MacroAction])
    }

    // MARK: - [보통] 이벤트 변환

    @Test("텍스트 입력 이벤트 -> MacroAction.type(text:) 변환")
    func textInputToTypeAction() async {
        let recorder = MacroRecorder()
        await recorder.startRecording()
        await recorder.recordTextInput("ls -la")
        let actions = await recorder.stopRecording()

        guard let first = actions.first else {
            #expect(Bool(false), "최소 1개 액션이 있어야 한다")
            return
        }

        if case .type(let text) = first {
            #expect(text == "ls -la")
        } else {
            #expect(Bool(false), ".type 액션이어야 한다")
        }
    }

    @Test("특수키 이벤트 -> MacroAction.keyPress 변환")
    func specialKeyToKeyPressAction() async {
        let recorder = MacroRecorder()
        await recorder.startRecording()
        await recorder.recordKeyPress(key: "Return", modifiers: [])
        let actions = await recorder.stopRecording()

        guard let first = actions.first else {
            #expect(Bool(false), "최소 1개 액션이 있어야 한다")
            return
        }

        if case .keyPress(let key, let modifiers) = first {
            #expect(key == "Return")
            #expect(modifiers.isEmpty)
        } else {
            #expect(Bool(false), ".keyPress 액션이어야 한다")
        }
    }

    @Test("500ms 이상 간격 -> MacroAction.wait 자동 삽입 확인")
    func autoInsertWaitOnDelay() async throws {
        let recorder = MacroRecorder()
        await recorder.startRecording()
        await recorder.recordTextInput("first")
        try await Task.sleep(for: .milliseconds(600))
        await recorder.recordTextInput("second")
        let actions = await recorder.stopRecording()

        // .type, .wait, .type 순서 예상
        #expect(actions.count >= 3)

        let hasWait = actions.contains { action in
            if case .wait = action { return true }
            return false
        }
        #expect(hasWait)
    }

    // MARK: - [어려움] 병합 / 빈 입력

    @Test("연속 타이핑 -> 단일 .type(text:)로 병합 확인")
    func consecutiveTypingMerged() async {
        let recorder = MacroRecorder()
        await recorder.startRecording()
        await recorder.recordTextInput("h")
        await recorder.recordTextInput("e")
        await recorder.recordTextInput("l")
        await recorder.recordTextInput("l")
        await recorder.recordTextInput("o")
        let actions = await recorder.stopRecording()

        // 연속 타이핑은 단일 .type("hello")로 병합
        let typeActions = actions.filter { action in
            if case .type = action { return true }
            return false
        }
        #expect(typeActions.count == 1)

        if case .type(let text) = typeActions.first {
            #expect(text == "hello")
        }
    }

    @Test("녹화 중 빈 입력 -> 빈 액션 배열 반환")
    func emptyRecordingReturnsEmptyActions() async {
        let recorder = MacroRecorder()
        await recorder.startRecording()
        let actions = await recorder.stopRecording()

        #expect(actions.isEmpty)
    }
}
