import Foundation

public actor ReconnectionManager {
    public private(set) var currentAttempt: Int = 0
    public private(set) var isCancelled: Bool = false

    private var stateContinuation: AsyncStream<ConnectionState>.Continuation?
    private var _stateStream: AsyncStream<ConnectionState>?

    public init() {
        let (stream, continuation) = AsyncStream<ConnectionState>.makeStream()
        self._stateStream = stream
        self.stateContinuation = continuation
    }

    public var stateStream: AsyncStream<ConnectionState> {
        _stateStream!
    }

    public func calculateDelay(forAttempt attempt: Int, baseDelay: Duration) -> Duration {
        let multiplier = 1 << attempt // 2^attempt
        let delaySeconds = baseDelay.components.seconds * Int64(multiplier)
        let maxDelay: Int64 = 30
        return .seconds(min(delaySeconds, maxDelay))
    }

    public func scheduleReconnect(
        for connection: any RemoteConnection,
        maxAttempts: Int = 5,
        baseDelay: Duration = .seconds(1)
    ) async {
        currentAttempt = 0
        isCancelled = false

        for attempt in 0..<maxAttempts {
            if isCancelled { return }

            currentAttempt = attempt
            stateContinuation?.yield(.reconnecting(attempt: attempt + 1))

            do {
                try await connection.connect()
                // Success
                currentAttempt = 0
                stateContinuation?.yield(.connected)
                return
            } catch {
                if attempt < maxAttempts - 1 {
                    let delay = calculateDelay(forAttempt: attempt, baseDelay: baseDelay)
                    try? await Task.sleep(for: delay)
                }
            }
        }

        // All attempts exhausted
        let error = ReconnectionError.maxAttemptsExceeded
        await connection.setState(.failed(error))
        stateContinuation?.yield(.failed(error))
    }

    public func cancelReconnect() {
        isCancelled = true
    }
}

public enum ReconnectionError: Error {
    case maxAttemptsExceeded
}

// Extension to allow setting state on any RemoteConnection (for mock)
extension RemoteConnection {
    func setState(_ state: ConnectionState) async {
        // Default no-op; MockRemoteConnection overrides
    }
}
