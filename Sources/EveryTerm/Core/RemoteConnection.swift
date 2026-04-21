import Foundation

public protocol RemoteConnection: Actor {
    nonisolated var id: UUID { get }
    var state: ConnectionState { get }
    var stateStream: AsyncStream<ConnectionState> { get }
    func connect() async throws
    func disconnect() async
    func send(_ data: Data) async throws
    var outputStream: AsyncStream<Data> { get }
}

// MARK: - RemoteConnectionError

public enum RemoteConnectionError: Error, Sendable {
    case notImplemented(String)
    case unsupportedProtocol
}

// MARK: - MockRemoteConnection

public actor MockRemoteConnection: RemoteConnection {
    public nonisolated let id: UUID = UUID()
    public private(set) var state: ConnectionState = .disconnected
    public private(set) var lastSentData: Data?

    private var shouldFailConnect: Bool = false
    private var failCount: Int = 0
    private var connectAttemptCount: Int = 0

    private var outputContinuation: AsyncStream<Data>.Continuation?
    private var _outputStream: AsyncStream<Data>?

    private var stateContinuation: AsyncStream<ConnectionState>.Continuation?
    private var _stateStream: AsyncStream<ConnectionState>?

    public init() {
        let (outputStream, outputCont) = AsyncStream<Data>.makeStream()
        self._outputStream = outputStream
        self.outputContinuation = outputCont

        let (stateStream, stateCont) = AsyncStream<ConnectionState>.makeStream()
        self._stateStream = stateStream
        self.stateContinuation = stateCont
    }

    public var outputStream: AsyncStream<Data> {
        _outputStream!
    }

    public var stateStream: AsyncStream<ConnectionState> {
        _stateStream!
    }

    public func connect() async throws {
        state = .connecting
        stateContinuation?.yield(.connecting)

        connectAttemptCount += 1

        if shouldFailConnect && (failCount == 0 || connectAttemptCount <= failCount) {
            let error = MockConnectionError.connectionFailed
            state = .failed(error)
            stateContinuation?.yield(.failed(error))
            throw error
        }

        state = .connected
        stateContinuation?.yield(.connected)
    }

    public func disconnect() async {
        state = .disconnected
        stateContinuation?.yield(.disconnected)
    }

    public func send(_ data: Data) async throws {
        lastSentData = data
    }

    public func simulateOutput(_ data: Data) {
        outputContinuation?.yield(data)
    }

    public func setShouldFailConnect(_ shouldFail: Bool) {
        shouldFailConnect = shouldFail
        if shouldFail {
            failCount = 0 // 0 means always fail
        }
    }

    public func setFailCount(_ count: Int) {
        shouldFailConnect = true
        failCount = count
        connectAttemptCount = 0
    }

    public func setState(_ newState: ConnectionState) {
        state = newState
        stateContinuation?.yield(newState)
    }
}

public enum MockConnectionError: Error {
    case connectionFailed
}
