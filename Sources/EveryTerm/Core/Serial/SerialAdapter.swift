import Foundation
import Darwin

public enum SerialConnectionError: Error {
    case invalidConfiguration(String)
    case openFailed(String)
    case notConnected
    case writeFailed(String)
}

public actor SerialAdapter: RemoteConnection {
    public nonisolated let id: UUID = UUID()
    public private(set) var state: ConnectionState = .disconnected

    // FIX-3: devicePath 허용 prefix 리스트. 임의 절대 경로로 민감 파일을 여는 것을 차단한다.
    public static let allowedDevicePathPrefixes: [String] = [
        "/dev/tty.",
        "/dev/cu.",
        "/dev/ttyS",
        "/dev/ttyUSB"
    ]

    public static func isValidDevicePath(_ path: String) -> Bool {
        allowedDevicePathPrefixes.contains(where: { path.hasPrefix($0) })
    }

    private let config: SerialSessionConfig
    // Snapshot of configuration values captured at init time (MainActor-isolated read)
    private let devicePath: String
    private let baudRate: Int
    private let dataBits: Int
    private let stopBits: Int
    private let parity: SerialParity
    private let flowControl: SerialFlowControl

    private var fileDescriptor: Int32 = -1

    private var stateContinuation: AsyncStream<ConnectionState>.Continuation?
    private var _stateStream: AsyncStream<ConnectionState>?
    private var outputContinuation: AsyncStream<Data>.Continuation?
    private var _outputStream: AsyncStream<Data>?

    // FIX-1: POSIX fd 로부터 수신하는 dispatch source. actor 격리 유지를 위해 핸들러 내부에서 Task hop.
    private var readSource: DispatchSourceRead?
    private static let readQueue = DispatchQueue(label: "com.everyterm.serial.read", qos: .userInitiated)

    @MainActor
    public init(config: SerialSessionConfig) {
        self.config = config
        self.devicePath = config.devicePath
        self.baudRate = config.baudRate
        self.dataBits = config.dataBits
        self.stopBits = config.stopBits
        self.parity = SerialParity(rawValue: config.parityRaw) ?? .none
        self.flowControl = SerialFlowControl(rawValue: config.flowControlRaw) ?? .none

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

    public func connect() async throws {
        state = .connecting
        stateContinuation?.yield(.connecting)

        // Validate baudRate first (no open needed)
        guard SerialSessionConfig.isAllowedBaudRate(baudRate) else {
            let err = SerialConnectionError.invalidConfiguration("Unsupported baudRate: \(baudRate)")
            state = .failed(err)
            stateContinuation?.yield(.failed(err))
            throw err
        }

        guard !devicePath.isEmpty else {
            let err = SerialConnectionError.invalidConfiguration("devicePath is empty")
            state = .failed(err)
            stateContinuation?.yield(.failed(err))
            throw err
        }

        // FIX-3: 허용 prefix 화이트리스트 검증. /etc/passwd 등 임의 경로로 open 금지.
        guard SerialAdapter.isValidDevicePath(devicePath) else {
            let prefixList = SerialAdapter.allowedDevicePathPrefixes.joined(separator: ", ")
            let err = SerialConnectionError.invalidConfiguration(
                "devicePath must match one of: " + prefixList
            )
            state = .failed(err)
            stateContinuation?.yield(.failed(err))
            throw err
        }

        let fd = devicePath.withCString { path in
            Darwin.open(path, O_RDWR | O_NOCTTY | O_NONBLOCK)
        }
        if fd < 0 {
            let err = SerialConnectionError.openFailed("open(\(devicePath)) failed: errno=\(errno)")
            state = .failed(err)
            stateContinuation?.yield(.failed(err))
            throw err
        }

        var t = Darwin.termios()
        if tcgetattr(fd, &t) != 0 {
            Darwin.close(fd)
            let err = SerialConnectionError.openFailed("tcgetattr failed")
            state = .failed(err)
            stateContinuation?.yield(.failed(err))
            throw err
        }

        do {
            try TermiosConfigurator.applyBaudRate(baudRate, to: &t)
            try TermiosConfigurator.applyFrameFormat(
                dataBits: dataBits,
                stopBits: stopBits,
                parity: parity,
                to: &t
            )
            try TermiosConfigurator.applyFlowControl(flowControl, to: &t)
            try TermiosConfigurator.applyRawMode(to: &t)
        } catch {
            Darwin.close(fd)
            state = .failed(error)
            stateContinuation?.yield(.failed(error))
            throw error
        }

        if tcsetattr(fd, TCSANOW, &t) != 0 {
            Darwin.close(fd)
            let err = SerialConnectionError.openFailed("tcsetattr failed")
            state = .failed(err)
            stateContinuation?.yield(.failed(err))
            throw err
        }

        fileDescriptor = fd
        state = .connected
        stateContinuation?.yield(.connected)

        startReadSource(fd: fd)
    }

    public func disconnect() async {
        if let src = readSource {
            src.cancel()
            readSource = nil
        }
        if fileDescriptor >= 0 {
            Darwin.close(fileDescriptor)
            fileDescriptor = -1
        }
        state = .disconnected
        stateContinuation?.yield(.disconnected)
    }

    public func send(_ data: Data) async throws {
        guard fileDescriptor >= 0 else {
            throw SerialConnectionError.notConnected
        }
        let fd = fileDescriptor
        try data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            guard let base = ptr.baseAddress else { return }
            let written = Darwin.write(fd, base, ptr.count)
            if written < 0 {
                throw SerialConnectionError.writeFailed("errno=\(errno)")
            }
        }
    }

    // FIX-1: fd 에서 non-blocking read 를 반복하여 outputContinuation 에 yield.
    // DispatchSourceRead 로 fd 가 read-ready 될 때만 깨어난다.
    private func startReadSource(fd: Int32) {
        let src = DispatchSource.makeReadSource(fileDescriptor: fd, queue: SerialAdapter.readQueue)
        src.setEventHandler { [weak self] in
            let bufSize = 4096
            var buffer = [UInt8](repeating: 0, count: bufSize)
            let n = buffer.withUnsafeMutableBufferPointer { ptr -> Int in
                guard let base = ptr.baseAddress else { return 0 }
                return Darwin.read(fd, base, bufSize)
            }
            if n > 0 {
                let chunk = Data(buffer.prefix(n))
                Task { [weak self] in
                    await self?.yieldReceived(chunk)
                }
            } else if n < 0 {
                let err = errno
                if err == EAGAIN || err == EWOULDBLOCK || err == EINTR {
                    return
                }
                // fd closed / real error: let disconnect path clean up.
                Task { [weak self] in
                    await self?.handleReadFailure()
                }
            }
            // n == 0 → EOF; DispatchSource will stop emitting. Treat as disconnection.
            if n == 0 {
                Task { [weak self] in
                    await self?.handleReadFailure()
                }
            }
        }
        src.setCancelHandler {
            // fd close is done in disconnect(); nothing to do here.
        }
        readSource = src
        src.resume()
    }

    private func yieldReceived(_ data: Data) {
        outputContinuation?.yield(data)
    }

    private func handleReadFailure() async {
        if case .disconnected = state { return }
        await disconnect()
    }
}
