import Testing
import Foundation
@testable import EveryTerm

@Suite("MacroPlayer Tests")
struct MacroPlayerTests {

    // MARK: - [쉬움] 초기 상태 / 빈 재생

    @Test("MacroPlayer 생성 후 isPlaying=false 확인")
    func initialNotPlaying() async {
        let player = MacroPlayer()
        let playing = await player.isPlaying

        #expect(playing == false)
    }

    @Test("빈 액션 배열 재생 -> 즉시 완료")
    func playEmptyActionsCompletesImmediately() async throws {
        let player = MacroPlayer()
        let mock = MockRemoteConnection()
        try await mock.connect()

        try await player.play(actions: [], on: mock)
        let playing = await player.isPlaying

        #expect(playing == false)
    }

    // MARK: - [보통] 액션 실행

    @Test("type(text:) 액션 -> Mock 연결에 send() 호출 확인")
    func typeActionSendsData() async throws {
        let player = MacroPlayer()
        let mock = MockRemoteConnection()
        try await mock.connect()

        let actions: [MacroAction] = [.type(text: "ls -la\n")]
        try await player.play(actions: actions, on: mock)

        let sent = await mock.lastSentData
        #expect(sent == Data("ls -la\n".utf8))
    }

    @Test("keyPress 액션 -> 특수키 코드 변환 후 send() 확인")
    func keyPressActionSendsKeyCode() async throws {
        let player = MacroPlayer()
        let mock = MockRemoteConnection()
        try await mock.connect()

        let actions: [MacroAction] = [.keyPress(key: "Return", modifiers: [])]
        try await player.play(actions: actions, on: mock)

        let sent = await mock.lastSentData
        #expect(sent != nil)
    }

    @Test("wait(seconds:) 액션 -> 지정 시간 대기 확인 (허용 오차 내)")
    func waitActionDelays() async throws {
        let player = MacroPlayer()
        let mock = MockRemoteConnection()
        try await mock.connect()

        let actions: [MacroAction] = [.wait(seconds: 0.2)]

        let start = ContinuousClock.now
        try await player.play(actions: actions, on: mock)
        let elapsed = ContinuousClock.now - start

        #expect(elapsed >= .milliseconds(150))
        #expect(elapsed <= .milliseconds(500))
    }

    @Test("재생 중지 -> 나머지 액션 스킵 확인")
    func stopSkipsRemainingActions() async throws {
        let player = MacroPlayer()
        let mock = MockRemoteConnection()
        try await mock.connect()

        let actions: [MacroAction] = [
            .type(text: "first"),
            .wait(seconds: 5.0), // 긴 대기
            .type(text: "second"), // 스킵되어야 함
        ]

        Task {
            try await Task.sleep(for: .milliseconds(100))
            await player.stop()
        }

        try await player.play(actions: actions, on: mock)

        let sent = await mock.lastSentData
        // "second"는 전송되지 않아야 함
        #expect(sent != Data("second".utf8))
    }

    // MARK: - [어려움] waitForOutput / 일시정지

    @Test("waitForOutput(pattern:timeout:) -> 정규식 매칭 성공 시 진행")
    func waitForOutputPatternMatch() async throws {
        let player = MacroPlayer()
        let mock = MockRemoteConnection()
        try await mock.connect()

        let actions: [MacroAction] = [
            .waitForOutput(pattern: "\\$\\s*$", timeout: 5.0),
        ]

        // 패턴 매칭 출력 시뮬레이션
        Task {
            try await Task.sleep(for: .milliseconds(100))
            await mock.simulateOutput(Data("user@host:~$ ".utf8))
        }

        try await player.play(actions: actions, on: mock)

        let playing = await player.isPlaying
        #expect(playing == false) // 정상 완료
    }

    @Test("waitForOutput 타임아웃 -> 에러 발생 확인")
    func waitForOutputTimeout() async throws {
        let player = MacroPlayer()
        let mock = MockRemoteConnection()
        try await mock.connect()

        let actions: [MacroAction] = [
            .waitForOutput(pattern: "never_matching_pattern", timeout: 0.1),
        ]

        await #expect(throws: MacroPlayerError.self) {
            try await player.play(actions: actions, on: mock)
        }
    }

    @Test("재생 일시정지/재개 -> 액션 연속성 유지 확인")
    func pauseResumeActionContinuity() async throws {
        let player = MacroPlayer()
        let mock = MockRemoteConnection()
        try await mock.connect()

        let actions: [MacroAction] = [
            .type(text: "first"),
            .wait(seconds: 0.5),
            .type(text: "second"),
        ]

        Task {
            try await Task.sleep(for: .milliseconds(50))
            await player.pause()
            try await Task.sleep(for: .milliseconds(200))
            await player.resume()
        }

        try await player.play(actions: actions, on: mock)

        let sent = await mock.lastSentData
        #expect(sent == Data("second".utf8))
    }
}
