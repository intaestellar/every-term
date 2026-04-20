import Foundation

// STUB: FreeRDP XCFramework 미통합 상태. 배포 준비 단계에서 완전 구현 예정.
public actor RDPAdapter: RemoteConnection {
    public nonisolated let id: UUID = UUID()
    public private(set) var state: ConnectionState = .disconnected

    // Snapshot of config values used to enrich the stub's notImplemented error message.
    private nonisolated let host: String
    private nonisolated let port: Int

    private var stateContinuation: AsyncStream<ConnectionState>.Continuation?
    private var _stateStream: AsyncStream<ConnectionState>?
    private var outputContinuation: AsyncStream<Data>.Continuation?
    private var _outputStream: AsyncStream<Data>?

    @MainActor
    public init(host: String, config: RDPSessionConfig) {
        self.host = host
        // Default RDP port 3389; gatewayPort is used if configured (stub never connects).
        self.port = config.gatewayPort ?? 3389

        let (stateStream, stateCont) = AsyncStream<ConnectionState>.makeStream()
        self._stateStream = stateStream
        self.stateContinuation = stateCont

        let (outputStream, outputCont) = AsyncStream<Data>.makeStream()
        self._outputStream = outputStream
        self.outputContinuation = outputCont
    }

    public var stateStream: AsyncStream<ConnectionState> {
        _stateStream!
    }

    public var outputStream: AsyncStream<Data> {
        _outputStream!
    }

    // MVP: RDP support is planned for v2.0
    public func connect() async throws {
        throw RemoteConnectionError.unsupportedProtocol
    }

    public func disconnect() async {
        // no-op
    }

    public func send(_ data: Data) async throws {
        // no-op stub
        _ = data
    }
}
