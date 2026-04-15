import Testing
import Foundation
@testable import EveryTerm

@Suite("TunnelAdapter Integration Tests")
struct TunnelAdapterIntegrationTests {

    // MARK: - [어려움] E2E 통합

    @Test("Local Forward: NIO echo 서버 -> 터널 경유 -> 데이터 왕복 E2E")
    func localForwardEchoE2E() async throws {
        // NIO echo 서버 + TunnelAdapter 경유 데이터 왕복
        let adapter = TunnelAdapter()
        let config = TunnelConfig(
            name: "E2E Echo",
            sessionId: UUID(),
            type: .local,
            localPort: 0, // 빈 포트 자동 할당
            remoteHost: "127.0.0.1",
            remotePort: 7777
        )
        let mockChannel = MockTunnelChannel()
        mockChannel.echoMode = true

        try await adapter.start(config: config, channel: mockChannel)

        let testPayload = Data("integration test payload".utf8)
        let response = try await adapter.sendAndReceive(testPayload)

        #expect(response == testPayload)

        await adapter.stop()
        let finalState = await adapter.state
        #expect(finalState == .stopped)
    }

    @Test("터널 연결 중 SSH 세션 끊김 -> 자동 재연결 후 터널 복구")
    func tunnelAutoReconnectOnDisconnect() async throws {
        let manager = TunnelManager()
        let config = TunnelConfig(
            name: "Reconnect E2E",
            sessionId: UUID(),
            type: .local,
            localPort: 0,
            remoteHost: "127.0.0.1",
            remotePort: 22
        )
        let mockChannel = MockTunnelChannel()

        try await manager.startTunnel(config: config, channel: mockChannel)

        // SSH 세션 끊김 시뮬레이션
        await manager.simulateTunnelDisconnect(id: config.id)

        // 재연결 완료 대기
        try await Task.sleep(for: .milliseconds(500))

        var recovered = false
        for await status in await manager.statusStream {
            if status.state == .running {
                recovered = true
                break
            }
        }

        #expect(recovered)
    }

    @Test("SOCKS5 프록시 경유 HTTP 요청 E2E")
    func socks5ProxyHttpRequestE2E() async throws {
        let adapter = TunnelAdapter()
        let config = TunnelConfig(
            name: "SOCKS5 E2E",
            sessionId: UUID(),
            type: .dynamic,
            localPort: 0,
            remoteHost: "",
            remotePort: 0
        )
        let mockChannel = MockTunnelChannel()
        mockChannel.echoMode = true

        try await adapter.start(config: config, channel: mockChannel)

        // SOCKS5 핸드셰이크
        let handshake = Data([0x05, 0x01, 0x00])
        let handshakeResponse = try await adapter.handleSOCKS5Handshake(handshake)
        #expect(handshakeResponse[0] == 0x05)
        #expect(handshakeResponse[1] == 0x00)

        // CONNECT 요청
        var connectRequest = Data([0x05, 0x01, 0x00, 0x03])
        let domain = "httpbin.org"
        connectRequest.append(UInt8(domain.count))
        connectRequest.append(contentsOf: domain.utf8)
        connectRequest.append(contentsOf: [0x00, 0x50]) // port 80

        let connectResponse = try await adapter.parseSOCKS5Connect(connectRequest)
        #expect(connectResponse.host == "httpbin.org")
        #expect(connectResponse.port == 80)

        await adapter.stop()
    }
}
