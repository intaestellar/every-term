import Foundation

public struct TerminalSize: Sendable {
    public let columns: UInt16
    public let rows: UInt16

    public init(columns: UInt16, rows: UInt16) {
        self.columns = columns
        self.rows = rows
    }
}

public actor LocalShellAdapter: RemoteConnection {
    public let id: UUID = UUID()
    public private(set) var state: ConnectionState = .disconnected
    public private(set) var currentSize: TerminalSize = TerminalSize(columns: 80, rows: 24)

    private var masterFd: Int32 = -1
    private var childPid: pid_t = 0
    private var readTask: Task<Void, Never>?
    private var monitorTask: Task<Void, Never>?

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

        var winSize = winsize(
            ws_row: currentSize.rows,
            ws_col: currentSize.columns,
            ws_xpixel: 0,
            ws_ypixel: 0
        )

        let pid = forkpty(&masterFd, nil, nil, &winSize)

        if pid < 0 {
            let error = LocalShellError.forkFailed
            state = .failed(error)
            stateContinuation?.yield(.failed(error))
            throw error
        }

        if pid == 0 {
            // Child process
            let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
            let args = [shell, "-l"]
            let cArgs = args.map { strdup($0) } + [nil]
            execv(shell, cArgs)
            _exit(1)
        }

        // Parent process
        childPid = pid
        state = .connected
        stateContinuation?.yield(.connected)

        // Start reading from PTY
        let fd = masterFd
        let continuation = outputContinuation
        readTask = Task.detached { [weak self] in
            let bufferSize = 4096
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }

            while true {
                let bytesRead = read(fd, buffer, bufferSize)
                if bytesRead <= 0 { break }
                let data = Data(bytes: buffer, count: bytesRead)
                continuation?.yield(data)
            }

            // Process ended
            await self?.handleProcessExit()
        }

        // Monitor child process
        let cpid = childPid
        monitorTask = Task.detached { [weak self] in
            var status: Int32 = 0
            waitpid(cpid, &status, 0)
            await self?.handleProcessExit()
        }
    }

    private func handleProcessExit() {
        guard case .connected = state else { return }
        state = .disconnected
        stateContinuation?.yield(.disconnected)
    }

    public func disconnect() async {
        if childPid > 0 {
            kill(childPid, SIGHUP)
            childPid = 0
        }
        if masterFd >= 0 {
            close(masterFd)
            masterFd = -1
        }
        readTask?.cancel()
        monitorTask?.cancel()
        state = .disconnected
        stateContinuation?.yield(.disconnected)
    }

    public func send(_ data: Data) async throws {
        guard masterFd >= 0 else {
            throw LocalShellError.notConnected
        }
        data.withUnsafeBytes { bytes in
            if let ptr = bytes.baseAddress {
                _ = write(masterFd, ptr, data.count)
            }
        }
    }

    public func resize(columns: UInt16, rows: UInt16) {
        currentSize = TerminalSize(columns: columns, rows: rows)
        guard masterFd >= 0 else { return }
        var winSize = winsize(
            ws_row: rows,
            ws_col: columns,
            ws_xpixel: 0,
            ws_ypixel: 0
        )
        ioctl(masterFd, TIOCSWINSZ, &winSize)
    }
}

public enum LocalShellError: Error {
    case forkFailed
    case notConnected
}
