import Testing
import Foundation
@testable import EveryTerm

@Suite("Reconnection Integration Tests")
struct ReconnectionIntegrationTests {

    @Test("연결 실패 → 자동 재연결 → 성공 시나리오")
    func failThenReconnectSuccess() async throws {
        let manager = ReconnectionManager()
        let mock = MockRemoteConnection()

        // 처음 2번 실패, 3번째 성공
        await mock.setFailCount(2)

        await manager.scheduleReconnect(for: mock, maxAttempts: 5, baseDelay: .milliseconds(1))

        let state = await mock.state
        if case .connected = state {
            #expect(true)
        } else {
            #expect(Bool(false), "재연결 성공 후 connected 상태여야 한다")
        }
    }

    @Test("연결 실패 → 최대 재시도 초과 → failed 시나리오")
    func failExceedMaxAttempts() async throws {
        let manager = ReconnectionManager()
        let mock = MockRemoteConnection()
        await mock.setShouldFailConnect(true) // 항상 실패

        await manager.scheduleReconnect(for: mock, maxAttempts: 3, baseDelay: .milliseconds(1))

        let state = await mock.state
        if case .failed = state {
            #expect(true)
        } else {
            #expect(Bool(false), "최대 재시도 초과 후 failed 상태여야 한다")
        }
    }

    @Test("재연결 중 수동 disconnect 호출 시 재연결 중단")
    func manualDisconnectCancelsReconnection() async throws {
        let manager = ReconnectionManager()
        let mock = MockRemoteConnection()
        await mock.setShouldFailConnect(true)

        Task {
            await manager.scheduleReconnect(for: mock, maxAttempts: 10, baseDelay: .seconds(1))
        }

        // 약간의 지연 후 수동 disconnect
        try await Task.sleep(for: .milliseconds(50))
        await manager.cancelReconnect()

        let isCancelled = await manager.isCancelled
        #expect(isCancelled == true)
    }
}
