import Testing
import Foundation
@testable import EveryTerm

@Suite("Macro Integration Tests")
struct MacroIntegrationTests {

    // MARK: - [어려움] E2E 통합

    @Test("매크로 녹화 -> 저장 -> 재생 E2E")
    func recordSavePlayE2E() async throws {
        // 1. 녹화
        let recorder = MacroRecorder()
        await recorder.startRecording()
        await recorder.recordTextInput("echo hello")
        await recorder.recordKeyPress(key: "Return", modifiers: [])
        let recordedActions = await recorder.stopRecording()

        #expect(!recordedActions.isEmpty)

        // 2. 직렬화 (저장 시뮬레이션)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(recordedActions)
        let restoredActions = try decoder.decode([MacroAction].self, from: data)

        #expect(restoredActions.count == recordedActions.count)

        // 3. 재생
        let player = MacroPlayer()
        let mock = MockRemoteConnection()
        try await mock.connect()

        try await player.play(actions: restoredActions, on: mock)

        let sent = await mock.lastSentData
        #expect(sent != nil)
    }

    @Test("waitForOutput 포함 매크로 -> Mock 출력 패턴 매칭 E2E")
    func waitForOutputPatternMatchingE2E() async throws {
        let player = MacroPlayer()
        let mock = MockRemoteConnection()
        try await mock.connect()

        let actions: [MacroAction] = [
            .type(text: "ssh user@server\n"),
            .waitForOutput(pattern: "password:", timeout: 3.0),
            .type(text: "secret123\n"),
        ]

        // 비동기로 출력 시뮬레이션
        Task {
            try await Task.sleep(for: .milliseconds(200))
            await mock.simulateOutput(Data("user@server's password: ".utf8))
        }

        try await player.play(actions: actions, on: mock)

        let sent = await mock.lastSentData
        #expect(sent == Data("secret123\n".utf8))
    }
}
