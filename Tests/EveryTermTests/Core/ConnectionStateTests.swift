import Testing
@testable import EveryTerm

@Suite("ConnectionState Tests")
struct ConnectionStateTests {

    @Test(".disconnected 상태 생성 및 비교")
    func disconnectedState() {
        let state = ConnectionState.disconnected
        if case .disconnected = state {
            #expect(true)
        } else {
            #expect(Bool(false), "disconnected 상태여야 한다")
        }
    }

    @Test(".connecting 상태 생성 및 비교")
    func connectingState() {
        let state = ConnectionState.connecting
        if case .connecting = state {
            #expect(true)
        } else {
            #expect(Bool(false), "connecting 상태여야 한다")
        }
    }

    @Test(".connected 상태 생성 및 비교")
    func connectedState() {
        let state = ConnectionState.connected
        if case .connected = state {
            #expect(true)
        } else {
            #expect(Bool(false), "connected 상태여야 한다")
        }
    }

    @Test(".reconnecting(attempt:) 연관값 접근 확인")
    func reconnectingState() {
        let state = ConnectionState.reconnecting(attempt: 3)
        if case .reconnecting(let attempt) = state {
            #expect(attempt == 3)
        } else {
            #expect(Bool(false), "reconnecting 상태여야 한다")
        }
    }

    @Test(".failed(Error) 연관값에서 에러 추출 확인")
    func failedState() {
        struct TestError: Error, Equatable {}
        let state = ConnectionState.failed(TestError())
        if case .failed(let error) = state {
            #expect(error is TestError)
        } else {
            #expect(Bool(false), "failed 상태여야 한다")
        }
    }
}
