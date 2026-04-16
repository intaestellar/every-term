import Testing
import Foundation
@testable import EveryTerm

@Suite("TunnelAdapter Tests")
struct TunnelAdapterTests {

    // MARK: - [쉬움] 초기 상태

    @Test("TunnelAdapter 생성 후 초기 상태 .stopped 확인")
    func initialStateStopped() async {
        let adapter = TunnelAdapter()
        let state = await adapter.state

        #expect(state == .stopped)
    }

    @Test("sentBytes 초기값 0 확인")
    func initialSentBytesZero() async {
        let adapter = TunnelAdapter()
        let bytes = await adapter.sentBytes

        #expect(bytes == 0)
    }

    @Test("receivedBytes 초기값 0 확인")
    func initialReceivedBytesZero() async {
        let adapter = TunnelAdapter()
        let bytes = await adapter.receivedBytes

        #expect(bytes == 0)
    }

    @Test("activeConnections 초기값 0 확인")
    func initialActiveConnectionsZero() async {
        let adapter = TunnelAdapter()
        let count = await adapter.activeConnections

        #expect(count == 0)
    }

    // MARK: - [보통] 상태 전이

    @Test("Local Forward 시작 -> 상태 .running 전이")
    func startLocalForwardRunning() async throws {
        let adapter = TunnelAdapter()
        let config = TunnelConfig(
            name: "Test Local",
            sessionId: UUID(),
            type: .local,
            localPort: 0, // 빈 포트 자동 선택
            remoteHost: "localhost",
            remotePort: 22
        )
        let mockChannel = MockTunnelChannel()

        try await adapter.start(config: config, channel: mockChannel)
        let state = await adapter.state

        #expect(state == .running)
    }

    @Test("Local Forward 중지 -> 상태 .stopped 전이")
    func stopLocalForwardStopped() async throws {
        let adapter = TunnelAdapter()
        let config = TunnelConfig(
            name: "Test Local",
            sessionId: UUID(),
            type: .local,
            localPort: 0,
            remoteHost: "localhost",
            remotePort: 22
        )
        let mockChannel = MockTunnelChannel()

        try await adapter.start(config: config, channel: mockChannel)
        await adapter.stop()
        let state = await adapter.state

        #expect(state == .stopped)
    }

    @Test("이미 사용 중인 포트 바인딩 시 PortConflictError 발생")
    func portConflictError() async throws {
        let adapter1 = TunnelAdapter()
        let adapter2 = TunnelAdapter()
        let config1 = TunnelConfig(
            name: "Tunnel 1",
            sessionId: UUID(),
            type: .local,
            localPort: 19999,
            remoteHost: "localhost",
            remotePort: 22
        )
        let config2 = TunnelConfig(
            name: "Tunnel 2",
            sessionId: UUID(),
            type: .local,
            localPort: 19999, // 같은 포트
            remoteHost: "localhost",
            remotePort: 80
        )
        let mockChannel1 = MockTunnelChannel()
        let mockChannel2 = MockTunnelChannel()

        try await adapter1.start(config: config1, channel: mockChannel1)

        await #expect(throws: PortConflictError.self) {
            try await adapter2.start(config: config2, channel: mockChannel2)
        }

        await adapter1.stop()
    }

    @Test("전송량 카운터 증가 확인 (Mock 데이터 전송 후 sentBytes > 0)")
    func sentBytesIncrement() async throws {
        let adapter = TunnelAdapter()
        let config = TunnelConfig(
            name: "Counter Test",
            sessionId: UUID(),
            type: .local,
            localPort: 0,
            remoteHost: "localhost",
            remotePort: 22
        )
        let mockChannel = MockTunnelChannel()

        try await adapter.start(config: config, channel: mockChannel)
        await adapter.recordSentBytes(1024)
        let bytes = await adapter.sentBytes

        #expect(bytes > 0)
        await adapter.stop()
    }

    // MARK: - [어려움] 고급 포워딩

    @Test("Local Forward: 로컬 echo 서버 -> 터널 경유 데이터 왕복 확인")
    func localForwardEchoRoundTrip() async throws {
        let adapter = TunnelAdapter()
        let config = TunnelConfig(
            name: "Echo Test",
            sessionId: UUID(),
            type: .local,
            localPort: 0,
            remoteHost: "localhost",
            remotePort: 7777
        )
        let mockChannel = MockTunnelChannel()
        mockChannel.echoMode = true

        try await adapter.start(config: config, channel: mockChannel)

        let testData = Data("hello echo".utf8)
        let response = try await adapter.sendAndReceive(testData)

        #expect(response == testData)
        await adapter.stop()
    }

    @Test("Remote Forward 요청 -> 채널 생성 확인")
    func remoteForwardChannelCreation() async throws {
        let adapter = TunnelAdapter()
        let config = TunnelConfig(
            name: "Remote Forward",
            sessionId: UUID(),
            type: .remote,
            localPort: 8080,
            remoteHost: "0.0.0.0",
            remotePort: 9090
        )
        let mockChannel = MockTunnelChannel()

        try await adapter.start(config: config, channel: mockChannel)
        let channelCreated = await mockChannel.isForwardRequested

        #expect(channelCreated == true)
        await adapter.stop()
    }

    @Test("Dynamic Forward (SOCKS5): 핸드셰이크 파싱 - 버전/메서드 확인")
    func dynamicForwardHandshake() async throws {
        let adapter = TunnelAdapter()
        let config = TunnelConfig(
            name: "SOCKS5 Dynamic",
            sessionId: UUID(),
            type: .dynamic,
            localPort: 0,
            remoteHost: "",
            remotePort: 0
        )
        let mockChannel = MockTunnelChannel()

        try await adapter.start(config: config, channel: mockChannel)

        let handshake = Data([0x05, 0x01, 0x00])
        let response = try await adapter.handleSOCKS5Handshake(handshake)

        #expect(response[0] == 0x05)
        #expect(response[1] == 0x00)
        await adapter.stop()
    }

    @Test("SOCKS5 CONNECT 요청 파싱 - 대상 호스트:포트 추출 확인")
    func socks5ConnectRequestParsing() async throws {
        let adapter = TunnelAdapter()
        let config = TunnelConfig(
            name: "SOCKS5 Connect",
            sessionId: UUID(),
            type: .dynamic,
            localPort: 0,
            remoteHost: "",
            remotePort: 0
        )
        let mockChannel = MockTunnelChannel()

        try await adapter.start(config: config, channel: mockChannel)

        var connectRequest = Data([0x05, 0x01, 0x00, 0x03])
        let domain = "example.com"
        connectRequest.append(UInt8(domain.count))
        connectRequest.append(contentsOf: domain.utf8)
        connectRequest.append(contentsOf: [0x00, 0x50]) // port 80

        let parsed = try await adapter.parseSOCKS5Connect(connectRequest)

        #expect(parsed.host == "example.com")
        #expect(parsed.port == 80)
        await adapter.stop()
    }
}
