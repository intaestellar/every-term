import Testing
import Foundation
@testable import EveryTerm

@Suite("ReconnectionManager Tests")
struct ReconnectionManagerTests {

    // MARK: - [보통] 지수 백오프 간격

    @Test("1차 재시도 지연: baseDelay (1초)")
    func firstRetryDelay() async {
        let manager = ReconnectionManager()
        let delay = await manager.calculateDelay(forAttempt: 0, baseDelay: .seconds(1))
        #expect(delay == .seconds(1))
    }

    @Test("2차 재시도 지연: 2초")
    func secondRetryDelay() async {
        let manager = ReconnectionManager()
        let delay = await manager.calculateDelay(forAttempt: 1, baseDelay: .seconds(1))
        #expect(delay == .seconds(2))
    }

    @Test("3차 재시도 지연: 4초")
    func thirdRetryDelay() async {
        let manager = ReconnectionManager()
        let delay = await manager.calculateDelay(forAttempt: 2, baseDelay: .seconds(1))
        #expect(delay == .seconds(4))
    }

    @Test("n차 재시도 지연: min(baseDelay * 2^n, 30초) 상한 검증")
    func maxDelayCapAt30Seconds() async {
        let manager = ReconnectionManager()
        // attempt 10 → 1 * 2^10 = 1024초 → 상한 30초
        let delay = await manager.calculateDelay(forAttempt: 10, baseDelay: .seconds(1))
        #expect(delay == .seconds(30))
    }

    @Test("최대 재시도 횟수(기본 5) 초과 시 .failed 상태 전이")
    func exceedMaxAttemptsTransitionsToFailed() async throws {
        let manager = ReconnectionManager()
        let mock = MockRemoteConnection()
        await mock.setShouldFailConnect(true)

        await manager.scheduleReconnect(for: mock, maxAttempts: 5, baseDelay: .milliseconds(1))

        let state = await mock.state
        if case .failed = state {
            #expect(true)
        } else {
            #expect(Bool(false), "최대 재시도 초과 후 failed 상태여야 한다")
        }
    }

    @Test("재연결 성공 시 재시도 카운터 리셋")
    func successfulReconnectResetsCounter() async throws {
        let manager = ReconnectionManager()
        let attemptCount = await manager.currentAttempt
        #expect(attemptCount == 0)

        let mock = MockRemoteConnection()
        await mock.setShouldFailConnect(false)

        await manager.scheduleReconnect(for: mock, maxAttempts: 5, baseDelay: .milliseconds(1))

        let resetCount = await manager.currentAttempt
        #expect(resetCount == 0)
    }

    @Test("커스텀 maxAttempts / baseDelay 설정 동작")
    func customConfiguration() async {
        let manager = ReconnectionManager()
        let delay = await manager.calculateDelay(forAttempt: 0, baseDelay: .seconds(2))
        #expect(delay == .seconds(2))
    }

    // MARK: - [보통] 상태 스트림 이벤트

    @Test("재연결 시도 시 .reconnecting(attempt: N) 이벤트 발행 확인")
    func reconnectingEventEmitted() async throws {
        let manager = ReconnectionManager()
        let mock = MockRemoteConnection()
        await mock.setShouldFailConnect(true)

        let stream = await manager.stateStream

        Task {
            await manager.scheduleReconnect(for: mock, maxAttempts: 2, baseDelay: .milliseconds(1))
        }

        var gotReconnecting = false
        for await state in stream {
            if case .reconnecting = state {
                gotReconnecting = true
                break
            }
        }
        #expect(gotReconnecting)
    }

    @Test("최대 시도 초과 시 .failed 이벤트 발행 확인")
    func failedEventAfterMaxAttempts() async throws {
        let manager = ReconnectionManager()
        let mock = MockRemoteConnection()
        await mock.setShouldFailConnect(true)

        let stream = await manager.stateStream

        Task {
            await manager.scheduleReconnect(for: mock, maxAttempts: 1, baseDelay: .milliseconds(1))
        }

        var gotFailed = false
        for await state in stream {
            if case .failed = state {
                gotFailed = true
                break
            }
        }
        #expect(gotFailed)
    }

    @Test("재연결 성공 시 .connected 이벤트 발행 확인")
    func connectedEventOnSuccess() async throws {
        let manager = ReconnectionManager()
        let mock = MockRemoteConnection()
        await mock.setShouldFailConnect(false)

        let stream = await manager.stateStream

        Task {
            await manager.scheduleReconnect(for: mock, maxAttempts: 5, baseDelay: .milliseconds(1))
        }

        var gotConnected = false
        for await state in stream {
            if case .connected = state {
                gotConnected = true
                break
            }
        }
        #expect(gotConnected)
    }
}
