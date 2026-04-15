import Testing
import Foundation
@testable import EveryTerm

@Suite("MultiExecutionManager Tests")
struct MultiExecutionManagerTests {

    // MARK: - [쉬움] 초기 상태

    @Test("MultiExecutionManager 생성 후 대상 세션 목록 빈 배열 확인")
    func initialTargetSessionsEmpty() async {
        let manager = MultiExecutionManager()
        let sessions = await manager.targetSessions

        #expect(sessions.isEmpty)
    }

    @Test("대상 세션 추가/제거 확인")
    func addRemoveTargetSessions() async {
        let manager = MultiExecutionManager()
        let sessionId = UUID()

        await manager.addTarget(sessionId)
        var sessions = await manager.targetSessions
        #expect(sessions.count == 1)
        #expect(sessions.contains(sessionId))

        await manager.removeTarget(sessionId)
        sessions = await manager.targetSessions
        #expect(sessions.isEmpty)
    }

    // MARK: - [보통] 명령 전송 / Broadcast

    @Test("Mock 연결 1개 대상 명령 전송 -> 출력 수신 확인")
    func sendCommandToSingleConnection() async throws {
        let manager = MultiExecutionManager()
        let mock = MockRemoteConnection()
        try await mock.connect()

        await manager.registerConnection(mock)
        await manager.addTarget(mock.id)

        let results = try await manager.executeCommand("whoami")

        #expect(results.count == 1)
        #expect(results[mock.id] != nil)
    }

    @Test("Mock 연결 3개 대상 동시 명령 전송 -> 각각 출력 수신 확인")
    func sendCommandToMultipleConnections() async throws {
        let manager = MultiExecutionManager()
        var mocks: [MockRemoteConnection] = []

        for _ in 0..<3 {
            let mock = MockRemoteConnection()
            try await mock.connect()
            await manager.registerConnection(mock)
            await manager.addTarget(mock.id)
            mocks.append(mock)
        }

        let results = try await manager.executeCommand("uptime")

        #expect(results.count == 3)
        for mock in mocks {
            #expect(results[mock.id] != nil)
        }
    }

    @Test("Broadcast 모드: 입력 데이터 -> 모든 연결에 send() 호출 확인")
    func broadcastSendsToAll() async throws {
        let manager = MultiExecutionManager()
        var mocks: [MockRemoteConnection] = []

        for _ in 0..<3 {
            let mock = MockRemoteConnection()
            try await mock.connect()
            await manager.registerConnection(mock)
            await manager.addTarget(mock.id)
            mocks.append(mock)
        }

        let inputData = Data("hello broadcast".utf8)
        try await manager.broadcast(inputData)

        for mock in mocks {
            let sent = await mock.lastSentData
            #expect(sent == inputData)
        }
    }

    @Test("연결 실패 서버 -> 에러 서버 목록에 추가 확인")
    func failedServerTracking() async throws {
        let manager = MultiExecutionManager()
        let failingMock = MockRemoteConnection()
        await failingMock.setShouldFailConnect(true)

        await manager.registerConnection(failingMock)
        await manager.addTarget(failingMock.id)

        _ = try? await manager.executeCommand("test")

        let failedServers = await manager.failedServers
        #expect(failedServers.contains(failingMock.id))
    }

    // MARK: - [어려움] 스트리밍 / 히스토리 / 지연

    @Test("출력 스트리밍: 서버별 독립 버퍼로 실시간 수집 확인")
    func streamingOutputPerServer() async throws {
        let manager = MultiExecutionManager()
        let mock1 = MockRemoteConnection()
        let mock2 = MockRemoteConnection()
        try await mock1.connect()
        try await mock2.connect()

        await manager.registerConnection(mock1)
        await manager.registerConnection(mock2)
        await manager.addTarget(mock1.id)
        await manager.addTarget(mock2.id)

        let stream = await manager.outputStream

        await mock1.simulateOutput(Data("output1".utf8))
        await mock2.simulateOutput(Data("output2".utf8))

        var outputs: [UUID: Data] = [:]
        for await (serverId, data) in stream {
            outputs[serverId] = data
            if outputs.count == 2 { break }
        }

        #expect(outputs[mock1.id] != nil)
        #expect(outputs[mock2.id] != nil)
    }

    @Test("히스토리: 멀티 실행 기록 저장/조회 (최근 50개 제한)")
    func historyLimitedTo50() async throws {
        let manager = MultiExecutionManager()
        let mock = MockRemoteConnection()
        try await mock.connect()
        await manager.registerConnection(mock)
        await manager.addTarget(mock.id)

        for i in 0..<55 {
            _ = try? await manager.executeCommand("command-\(i)")
        }

        let history = await manager.executionHistory
        #expect(history.count <= 50)
    }

    @Test("일부 서버 응답 지연 시 다른 서버 출력은 즉시 수신 확인")
    func partialDelayDoesNotBlockOthers() async throws {
        let manager = MultiExecutionManager()
        let fastMock = MockRemoteConnection()
        let slowMock = MockRemoteConnection()
        try await fastMock.connect()
        try await slowMock.connect()

        await manager.registerConnection(fastMock)
        await manager.registerConnection(slowMock)
        await manager.addTarget(fastMock.id)
        await manager.addTarget(slowMock.id)

        // 빠른 서버 즉시 응답 시뮬레이션
        await fastMock.simulateOutput(Data("fast response".utf8))

        let stream = await manager.outputStream
        var firstReceived: UUID?

        for await (serverId, _) in stream {
            firstReceived = serverId
            break
        }

        #expect(firstReceived == fastMock.id)
    }
}
