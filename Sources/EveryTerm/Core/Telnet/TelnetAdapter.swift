import Foundation
import Network

public enum TelnetConnectionError: Error {
    case connectionFailed(String)
    case notConnected
    case invalidHost(String)
}

/// Telnet is an unencrypted protocol. Credentials and session data are transmitted in plaintext.
/// Use only on trusted networks; prefer SSH for production systems.
///
/// UI integration: `SecurityWarningBanner` is rendered above the terminal surface
/// for `SessionType.telnet` tabs in `MainWindowView`.
public actor TelnetAdapter: RemoteConnection {
    public nonisolated let id: UUID = UUID()
    public private(set) var state: ConnectionState = .disconnected

    public let host: String
    public let port: Int

    private var connection: NWConnection?
    private var parser = TelnetParser()
    private let negotiator = TelnetOptionNegotiator()

    private var stateContinuation: AsyncStream<ConnectionState>.Continuation?
    private var _stateStream: AsyncStream<ConnectionState>?
    private var outputContinuation: AsyncStream<Data>.Continuation?
    private var _outputStream: AsyncStream<Data>?

    private let appLogger = AppLogger(logLevel: .info, label: "com.everyterm.telnet")

    public init(host: String, port: Int = 23) {
        self.host = host
        self.port = port

        let (stateStream, stateCont) = AsyncStream<ConnectionState>.makeStream()
        self._stateStream = stateStream
        self.stateContinuation = stateCont

        // FIX-5: outputStream 버퍼링 상한을 두어 소비자가 뒤처질 때 OOM 을 방지한다.
        // 전략: bufferingNewest — 오래된 데이터를 drop 하고 최신을 유지. 터미널 UX 관점에서
        // 오래된 수신 버퍼가 쌓이는 것보다 최신 출력을 유지하는 편이 이득.
        let (outputStream, outputCont) = AsyncStream<Data>.makeStream(
            of: Data.self,
            bufferingPolicy: .bufferingNewest(1024)
        )
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
        // FIX-2: 평문 프로토콜 — 자격증명/세션 데이터가 암호화되지 않고 전송됨을 연결 시점에 경고.
        appLogger.warning(
            "Telnet is plaintext: credentials and session data are transmitted unencrypted (host=\(host):\(port)). Prefer SSH."
        )
        state = .connecting
        stateContinuation?.yield(.connecting)

        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
            let err = TelnetConnectionError.invalidHost("Invalid port \(port)")
            state = .failed(err)
            stateContinuation?.yield(.failed(err))
            throw err
        }

        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: nwPort
        )
        let params = NWParameters.tcp
        let conn = NWConnection(to: endpoint, using: params)
        self.connection = conn

        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                nonisolated(unsafe) var resumed = false
                conn.stateUpdateHandler = { nwState in
                    switch nwState {
                    case .ready:
                        if !resumed {
                            resumed = true
                            cont.resume()
                        }
                    case .failed(let error):
                        if !resumed {
                            resumed = true
                            cont.resume(throwing: error)
                        }
                    case .cancelled:
                        if !resumed {
                            resumed = true
                            cont.resume(throwing: TelnetConnectionError.connectionFailed("Cancelled"))
                        }
                    case .waiting(let error):
                        // DNS resolution failure or transient unreachable host — treat as failure immediately
                        if !resumed {
                            resumed = true
                            cont.resume(throwing: error)
                        }
                    default:
                        break
                    }
                }
                conn.start(queue: .global(qos: .userInitiated))
            }
        } catch {
            state = .failed(error)
            stateContinuation?.yield(.failed(error))
            connection?.cancel()
            connection = nil
            throw error
        }

        state = .connected
        stateContinuation?.yield(.connected)
        startReceiveLoop()
    }

    public func disconnect() async {
        connection?.cancel()
        connection = nil
        state = .disconnected
        stateContinuation?.yield(.disconnected)
    }

    public func send(_ data: Data) async throws {
        let isConnected: Bool
        if case .connected = state { isConnected = true } else { isConnected = false }
        guard let conn = connection, isConnected else {
            throw TelnetConnectionError.notConnected
        }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            conn.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    cont.resume(throwing: error)
                } else {
                    cont.resume()
                }
            })
        }
    }

    private func startReceiveLoop() {
        guard let conn = connection else { return }
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                Task { [weak self] in
                    guard let self = self else { return }
                    await self.handleReceivedData(data)
                }
            }
            if error != nil || isComplete {
                Task { [weak self] in
                    await self?.handleDisconnection()
                }
                return
            }
            Task { [weak self] in
                await self?.continueReceiving()
            }
        }
    }

    private func continueReceiving() {
        startReceiveLoop()
    }

    private func handleReceivedData(_ data: Data) async {
        let result = parser.feed(data)
        if !result.data.isEmpty {
            outputContinuation?.yield(result.data)
        }
        for cmd in result.commands {
            let reply = await negotiator.respond(to: cmd)
            if !reply.isEmpty {
                try? await send(reply)
            }
        }
    }

    private func handleDisconnection() async {
        connection?.cancel()
        connection = nil
        state = .disconnected
        stateContinuation?.yield(.disconnected)
    }
}

