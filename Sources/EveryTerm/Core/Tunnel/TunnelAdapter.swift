import Foundation

public enum TunnelState: Sendable, Equatable {
    case stopped
    case starting
    case running
    case error(String)
}

public struct PortConflictError: Error, Sendable {
    public let port: Int
    public init(port: Int) {
        self.port = port
    }
}

/// Mock SSH tunnel channel for testing purposes
public final class MockTunnelChannel: @unchecked Sendable {
    private let lock = NSLock()

    private var _echoMode: Bool = false
    private var _isForwardRequested: Bool = false
    private var _shouldFailReconnect: Bool = false

    public var echoMode: Bool {
        get { lock.withLock { _echoMode } }
        set { lock.withLock { _echoMode = newValue } }
    }

    public var isForwardRequested: Bool {
        get { lock.withLock { _isForwardRequested } }
        set { lock.withLock { _isForwardRequested = newValue } }
    }

    public var shouldFailReconnect: Bool {
        get { lock.withLock { _shouldFailReconnect } }
        set { lock.withLock { _shouldFailReconnect = newValue } }
    }

    public init() {}

    public func requestForward() {
        isForwardRequested = true
    }

    public func echo(_ data: Data) -> Data {
        return data
    }
}

/// Tracks which local ports are in use across all TunnelAdapters
private final class PortRegistry: @unchecked Sendable {
    static let shared = PortRegistry()
    private var usedPorts: Set<Int> = []
    private let lock = NSLock()

    func reserve(_ port: Int) throws {
        lock.lock()
        defer { lock.unlock() }
        guard port == 0 || !usedPorts.contains(port) else {
            throw PortConflictError(port: port)
        }
        if port != 0 {
            usedPorts.insert(port)
        }
    }

    func release(_ port: Int) {
        lock.lock()
        defer { lock.unlock() }
        usedPorts.remove(port)
    }
}

public actor TunnelAdapter {
    public private(set) var state: TunnelState = .stopped
    public private(set) var sentBytes: Int64 = 0
    public private(set) var receivedBytes: Int64 = 0
    public private(set) var activeConnections: Int = 0

    private var tunnelType: TunnelType = .local
    private var channel: MockTunnelChannel?
    private var boundPort: Int = 0

    public init() {}

    public func start(localPort: Int, tunnelType: TunnelType, channel: MockTunnelChannel) async throws {
        try PortRegistry.shared.reserve(localPort)

        self.tunnelType = tunnelType
        self.channel = channel
        self.boundPort = localPort

        if tunnelType == .remote {
            channel.requestForward()
        }

        state = .running
        activeConnections = 1
    }

    public func start(config: TunnelConfig, channel: MockTunnelChannel) async throws {
        try await start(localPort: config.localPort, tunnelType: config.type, channel: channel)
    }

    public func stop() async {
        if boundPort != 0 {
            PortRegistry.shared.release(boundPort)
        }
        state = .stopped
        activeConnections = 0
        channel = nil
        boundPort = 0
    }

    public func recordSentBytes(_ count: Int64) {
        sentBytes += count
    }

    public func recordReceivedBytes(_ count: Int64) {
        receivedBytes += count
    }

    public func sendAndReceive(_ data: Data) async throws -> Data {
        guard let channel = channel else {
            throw TunnelAdapterError.notRunning
        }
        sentBytes += Int64(data.count)
        let response = channel.echo(data)
        receivedBytes += Int64(response.count)
        return response
    }

    public func handleSOCKS5Handshake(_ data: Data) async throws -> Data {
        let result = try SOCKS5Parser.parseHandshake(data)
        let method: UInt8 = result.methods.contains(0x00) ? 0x00 : 0xFF
        return SOCKS5Parser.buildHandshakeResponse(method: method)
    }

    public func parseSOCKS5Connect(_ data: Data) async throws -> SOCKS5ConnectRequest {
        return try SOCKS5Parser.parseConnectRequest(data)
    }
}

public enum TunnelAdapterError: Error, Sendable {
    case notRunning
}
