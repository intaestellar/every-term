import Testing
import Foundation
@testable import EveryTerm

@Suite("MockRemoteConnection Tests")
struct MockRemoteConnectionTests {

    @Test("Mock 생성 후 초기 상태 .disconnected 확인")
    func initialStateIsDisconnected() async {
        let mock = MockRemoteConnection()
        let state = await mock.state
        if case .disconnected = state {
            #expect(true)
        } else {
            #expect(Bool(false), "초기 상태는 disconnected여야 한다")
        }
    }

    @Test("connect() 호출 후 상태 .connected 전이 확인")
    func connectTransition() async throws {
        let mock = MockRemoteConnection()
        try await mock.connect()
        let state = await mock.state
        if case .connected = state {
            #expect(true)
        } else {
            #expect(Bool(false), "connect 후 connected 상태여야 한다")
        }
    }

    @Test("disconnect() 호출 후 상태 .disconnected 전이 확인")
    func disconnectTransition() async throws {
        let mock = MockRemoteConnection()
        try await mock.connect()
        await mock.disconnect()
        let state = await mock.state
        if case .disconnected = state {
            #expect(true)
        } else {
            #expect(Bool(false), "disconnect 후 disconnected 상태여야 한다")
        }
    }

    @Test("send(_:) 데이터 전달 확인")
    func sendData() async throws {
        let mock = MockRemoteConnection()
        try await mock.connect()
        let data = Data("hello".utf8)
        try await mock.send(data)
        let sentData = await mock.lastSentData
        #expect(sentData == data)
    }

    @Test("outputStream에서 데이터 수신 확인")
    func receiveOutput() async throws {
        let mock = MockRemoteConnection()
        try await mock.connect()

        let expected = Data("output".utf8)
        await mock.simulateOutput(expected)

        let stream = await mock.outputStream
        var received: Data?
        for await chunk in stream {
            received = chunk
            break
        }
        #expect(received == expected)
    }

    @Test("stateStream에서 상태 변경 이벤트 수신")
    func stateStreamEvents() async throws {
        let mock = MockRemoteConnection()
        let stream = await mock.stateStream

        try await mock.connect()

        var states: [ConnectionState] = []
        for await state in stream {
            states.append(state)
            if case .connected = state { break }
        }
        #expect(states.isEmpty == false)
    }
}
