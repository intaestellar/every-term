import Foundation

public struct TunnelStatus: Sendable {
    public var id: UUID
    public var state: TunnelState
    public var activeConnections: Int
    public var sentBytes: Int64
    public var receivedBytes: Int64

    public init(id: UUID, state: TunnelState, activeConnections: Int = 0, sentBytes: Int64 = 0, receivedBytes: Int64 = 0) {
        self.id = id
        self.state = state
        self.activeConnections = activeConnections
        self.sentBytes = sentBytes
        self.receivedBytes = receivedBytes
    }
}

/// Sendable snapshot of TunnelConfig values needed across actor boundaries
private struct TunnelConfigSnapshot: Sendable {
    let id: UUID
    let localPort: Int
    let tunnelType: TunnelType
    let sessionId: UUID
    let isAutoStart: Bool
}

public actor TunnelManager {
    private var adapters: [UUID: TunnelAdapter] = [:]
    private var channels: [UUID: MockTunnelChannel] = [:]
    private var configSnapshots: [UUID: TunnelConfigSnapshot] = [:]
    private var autoStartEntries: [(snapshot: TunnelConfigSnapshot, channel: MockTunnelChannel)] = []
    private var reconnecting: Set<UUID> = []

    private var statusContinuation: AsyncStream<TunnelStatus>.Continuation?
    private var _statusStream: AsyncStream<TunnelStatus>?

    public init() {
        let (stream, continuation) = AsyncStream<TunnelStatus>.makeStream()
        self._statusStream = stream
        self.statusContinuation = continuation
    }

    public var statusStream: AsyncStream<TunnelStatus> {
        _statusStream!
    }

    public var activeTunnelCount: Int {
        adapters.count
    }

    public func startTunnel(config: TunnelConfig, channel: MockTunnelChannel) async throws {
        let snapshot = TunnelConfigSnapshot(
            id: config.id,
            localPort: config.localPort,
            tunnelType: config.type,
            sessionId: config.sessionId,
            isAutoStart: config.isAutoStart
        )
        let adapter = TunnelAdapter()
        try await adapter.start(localPort: snapshot.localPort, tunnelType: snapshot.tunnelType, channel: channel)

        adapters[snapshot.id] = adapter
        channels[snapshot.id] = channel
        configSnapshots[snapshot.id] = snapshot

        let status = TunnelStatus(
            id: snapshot.id,
            state: .running,
            activeConnections: 1
        )
        statusContinuation?.yield(status)
    }

    public func stopTunnel(id: UUID) async {
        if let adapter = adapters[id] {
            await adapter.stop()
        }
        adapters.removeValue(forKey: id)
        channels.removeValue(forKey: id)
        configSnapshots.removeValue(forKey: id)
        reconnecting.remove(id)

        let status = TunnelStatus(id: id, state: .stopped)
        statusContinuation?.yield(status)
    }

    public func registerAutoStartTunnel(config: TunnelConfig, channel: MockTunnelChannel) {
        let snapshot = TunnelConfigSnapshot(
            id: config.id,
            localPort: config.localPort,
            tunnelType: config.type,
            sessionId: config.sessionId,
            isAutoStart: config.isAutoStart
        )
        autoStartEntries.append((snapshot: snapshot, channel: channel))
    }

    public func onSSHConnected(sessionId: UUID) async {
        for entry in autoStartEntries where entry.snapshot.sessionId == sessionId && entry.snapshot.isAutoStart {
            let adapter = TunnelAdapter()
            try? await adapter.start(localPort: entry.snapshot.localPort, tunnelType: entry.snapshot.tunnelType, channel: entry.channel)
            adapters[entry.snapshot.id] = adapter
            channels[entry.snapshot.id] = entry.channel
            configSnapshots[entry.snapshot.id] = entry.snapshot

            let status = TunnelStatus(id: entry.snapshot.id, state: .running, activeConnections: 1)
            statusContinuation?.yield(status)
        }
    }

    public func simulateTunnelDisconnect(id: UUID) async {
        guard let channel = channels[id] else { return }

        let shouldFail = channel.shouldFailReconnect

        if shouldFail {
            if let adapter = adapters[id] {
                await adapter.stop()
            }
            adapters.removeValue(forKey: id)
            reconnecting.insert(id)

            let status = TunnelStatus(id: id, state: .error("Max reconnection attempts exceeded"))
            statusContinuation?.yield(status)
        } else {
            reconnecting.insert(id)

            if let snapshot = configSnapshots[id] {
                if let adapter = adapters[id] {
                    await adapter.stop()
                }
                let newAdapter = TunnelAdapter()
                try? await newAdapter.start(localPort: snapshot.localPort, tunnelType: snapshot.tunnelType, channel: channel)
                adapters[id] = newAdapter

                let status = TunnelStatus(id: id, state: .running, activeConnections: 1)
                statusContinuation?.yield(status)
            }
        }
    }

    public func isReconnecting(id: UUID) -> Bool {
        reconnecting.contains(id)
    }
}
