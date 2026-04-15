import Foundation

public struct ExecutionRecord: Sendable {
    public let command: String
    public let timestamp: Date
    public let targetIds: [UUID]
}

public actor MultiExecutionManager {
    private var connections: [UUID: any RemoteConnection] = [:]
    public private(set) var targetSessions: [UUID] = []
    public private(set) var failedServers: Set<UUID> = []
    public private(set) var executionHistory: [ExecutionRecord] = []

    private var outputContinuation: AsyncStream<(UUID, Data)>.Continuation?
    private var _outputStream: AsyncStream<(UUID, Data)>?
    private var monitorTasks: [UUID: Task<Void, Never>] = [:]

    public init() {
        let (stream, continuation) = AsyncStream<(UUID, Data)>.makeStream()
        self._outputStream = stream
        self.outputContinuation = continuation
    }

    public var outputStream: AsyncStream<(UUID, Data)> {
        _outputStream!
    }

    public func addTarget(_ sessionId: UUID) {
        if !targetSessions.contains(sessionId) {
            targetSessions.append(sessionId)
        }
    }

    public func removeTarget(_ sessionId: UUID) {
        targetSessions.removeAll { $0 == sessionId }
    }

    public func registerConnection(_ connection: any RemoteConnection) {
        let connId = connection.id
        connections[connId] = connection

        // Monitor connection's output stream and forward to manager's output stream
        let continuation = outputContinuation
        let task = Task { [connId] in
            let stream = await connection.outputStream
            for await data in stream {
                continuation?.yield((connId, data))
            }
        }
        monitorTasks[connId] = task
    }

    public func executeCommand(_ command: String) async throws -> [UUID: String] {
        var results: [UUID: String] = [:]
        let targets = targetSessions

        await withTaskGroup(of: (UUID, String?).self) { group in
            for targetId in targets {
                group.addTask { [connections] in
                    guard let conn = connections[targetId] else {
                        return (targetId, nil)
                    }

                    do {
                        let state = await conn.state
                        guard case .connected = state else {
                            return (targetId, nil)
                        }
                        try await conn.send(Data((command + "\n").utf8))
                        return (targetId, "executed: \(command)")
                    } catch {
                        return (targetId, nil)
                    }
                }
            }

            for await (id, result) in group {
                if let result = result {
                    results[id] = result
                } else {
                    failedServers.insert(id)
                }
            }
        }

        // Record history
        let record = ExecutionRecord(command: command, timestamp: Date(), targetIds: targets)
        executionHistory.append(record)
        if executionHistory.count > 50 {
            executionHistory.removeFirst(executionHistory.count - 50)
        }

        return results
    }

    public func broadcast(_ data: Data) async throws {
        let targets = targetSessions

        for targetId in targets {
            guard let conn = connections[targetId] else {
                failedServers.insert(targetId)
                continue
            }

            let state = await conn.state
            guard case .connected = state else {
                failedServers.insert(targetId)
                continue
            }

            do {
                try await conn.send(data)
            } catch {
                failedServers.insert(targetId)
            }
        }
    }
}
