import Testing
import Foundation
@testable import EveryTerm

@Suite("MultiExecution Integration Tests")
struct MultiExecutionIntegrationTests {

    // MARK: - [어려움] E2E 통합

    @Test("3개 Mock 연결 -> 동시 명령 전송 -> 결과 수집 E2E")
    func threeServersConcurrentExecution() async throws {
        let manager = MultiExecutionManager()
        var mocks: [MockRemoteConnection] = []

        for _ in 0..<3 {
            let mock = MockRemoteConnection()
            try await mock.connect()
            await manager.registerConnection(mock)
            await manager.addTarget(mock.id)
            mocks.append(mock)
        }

        // 각 Mock에 응답 시뮬레이션
        for (index, mock) in mocks.enumerated() {
            Task {
                try await Task.sleep(for: .milliseconds(10 * (index + 1)))
                await mock.simulateOutput(Data("response-\(index)".utf8))
            }
        }

        let results = try await manager.executeCommand("hostname")

        #expect(results.count == 3)
        for mock in mocks {
            #expect(results[mock.id] != nil)
        }
    }

    @Test("Broadcast + 1개 서버 실패 -> 나머지 정상 수신 확인")
    func broadcastWithOneFailure() async throws {
        let manager = MultiExecutionManager()
        let goodMock1 = MockRemoteConnection()
        let goodMock2 = MockRemoteConnection()
        let badMock = MockRemoteConnection()

        try await goodMock1.connect()
        try await goodMock2.connect()
        // badMock은 연결하지 않음 (실패 시뮬레이션)
        await badMock.setShouldFailConnect(true)

        await manager.registerConnection(goodMock1)
        await manager.registerConnection(goodMock2)
        await manager.registerConnection(badMock)
        await manager.addTarget(goodMock1.id)
        await manager.addTarget(goodMock2.id)
        await manager.addTarget(badMock.id)

        let inputData = Data("broadcast message".utf8)
        try? await manager.broadcast(inputData)

        // 정상 서버들은 데이터 수신
        let sent1 = await goodMock1.lastSentData
        let sent2 = await goodMock2.lastSentData
        #expect(sent1 == inputData)
        #expect(sent2 == inputData)

        // 실패 서버 추적
        let failedServers = await manager.failedServers
        #expect(failedServers.contains(badMock.id))
    }
}
