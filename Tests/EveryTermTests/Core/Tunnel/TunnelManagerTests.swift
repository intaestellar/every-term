import Testing
import Foundation
@testable import EveryTerm

@Suite("TunnelManager Tests")
struct TunnelManagerTests {

    // MARK: - [쉬움] 초기 상태

    @Test("TunnelManager 생성 후 활성 터널 수 0 확인")
    func initialActiveTunnelCountZero() async {
        let manager = TunnelManager()
        let count = await manager.activeTunnelCount

        #expect(count == 0)
    }

    // MARK: - [보통] 상태 전이 / 자동 시작

    @Test("터널 시작 -> TunnelStatus 스트림에 .running 이벤트 수신")
    func startTunnelEmitsRunning() async throws {
        let manager = TunnelManager()
        let config = TunnelConfig(
            name: "Test Tunnel",
            sessionId: UUID(),
            type: .local,
            localPort: 0,
            remoteHost: "localhost",
            remotePort: 22
        )
        let mockChannel = MockTunnelChannel()

        try await manager.startTunnel(config: config, channel: mockChannel)

        var receivedRunning = false
        for await status in await manager.statusStream {
            if status.state == .running {
                receivedRunning = true
                break
            }
        }

        #expect(receivedRunning)
    }

    @Test("터널 중지 -> TunnelStatus 스트림에 .stopped 이벤트 수신")
    func stopTunnelEmitsStopped() async throws {
        let manager = TunnelManager()
        let config = TunnelConfig(
            name: "Stop Test",
            sessionId: UUID(),
            type: .local,
            localPort: 0,
            remoteHost: "localhost",
            remotePort: 22
        )
        let mockChannel = MockTunnelChannel()

        try await manager.startTunnel(config: config, channel: mockChannel)
        await manager.stopTunnel(id: config.id)

        var receivedStopped = false
        for await status in await manager.statusStream {
            if status.state == .stopped {
                receivedStopped = true
                break
            }
        }

        #expect(receivedStopped)
    }

    @Test("isAutoStart 터널: SSH 연결 완료 이벤트 -> 자동 시작 확인")
    func autoStartOnSSHConnect() async throws {
        let manager = TunnelManager()
        let sessionId = UUID()
        let config = TunnelConfig(
            name: "Auto Start",
            sessionId: sessionId,
            type: .local,
            localPort: 0,
            remoteHost: "localhost",
            remotePort: 22
        )
        config.isAutoStart = true
        let mockChannel = MockTunnelChannel()

        await manager.registerAutoStartTunnel(config: config, channel: mockChannel)
        await manager.onSSHConnected(sessionId: sessionId)

        let count = await manager.activeTunnelCount
        #expect(count > 0)
    }

    @Test("터널 끊김 -> ReconnectionManager 재연결 트리거 확인")
    func tunnelDisconnectTriggersReconnection() async throws {
        let manager = TunnelManager()
        let config = TunnelConfig(
            name: "Reconnect Test",
            sessionId: UUID(),
            type: .local,
            localPort: 0,
            remoteHost: "localhost",
            remotePort: 22
        )
        let mockChannel = MockTunnelChannel()

        try await manager.startTunnel(config: config, channel: mockChannel)
        await manager.simulateTunnelDisconnect(id: config.id)

        let isReconnecting = await manager.isReconnecting(id: config.id)
        #expect(isReconnecting == true)
    }

    // MARK: - [어려움] 동시성 / 백오프

    @Test("다중 터널 동시 시작/중지 - 상태 일관성 확인")
    func multipleTunnelsConcurrency() async throws {
        let manager = TunnelManager()
        var configs: [TunnelConfig] = []

        for i in 0..<5 {
            let config = TunnelConfig(
                name: "Tunnel \(i)",
                sessionId: UUID(),
                type: .local,
                localPort: 0,
                remoteHost: "localhost",
                remotePort: 22
            )
            configs.append(config)
        }

        // 동시 시작
        try await withThrowingTaskGroup(of: Void.self) { group in
            for config in configs {
                group.addTask {
                    let mockChannel = MockTunnelChannel()
                    try await manager.startTunnel(config: config, channel: mockChannel)
                }
            }
            try await group.waitForAll()
        }

        let activeCount = await manager.activeTunnelCount
        #expect(activeCount == 5)

        // 동시 중지
        await withTaskGroup(of: Void.self) { group in
            for config in configs {
                group.addTask {
                    await manager.stopTunnel(id: config.id)
                }
            }
        }

        let finalCount = await manager.activeTunnelCount
        #expect(finalCount == 0)
    }

    @Test("재연결 지수 백오프 - 최대 시도 횟수 초과 시 .error 상태")
    func reconnectionBackoffExceedsMaxAttempts() async throws {
        let manager = TunnelManager()
        let config = TunnelConfig(
            name: "Backoff Test",
            sessionId: UUID(),
            type: .local,
            localPort: 0,
            remoteHost: "localhost",
            remotePort: 22
        )
        let mockChannel = MockTunnelChannel()
        mockChannel.shouldFailReconnect = true

        try await manager.startTunnel(config: config, channel: mockChannel)
        await manager.simulateTunnelDisconnect(id: config.id)

        // 최대 시도 횟수 초과 대기
        try await Task.sleep(for: .milliseconds(500))

        var foundError = false
        for await status in await manager.statusStream {
            if case .error = status.state {
                foundError = true
                break
            }
        }

        #expect(foundError)
    }
}
