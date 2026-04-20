import Foundation
// TODO: Remove @preconcurrency when Citadel fully supports Swift 6 Sendable
@preconcurrency import Citadel
@preconcurrency import NIO
import NIOSSH
import Crypto
import Logging

public enum SSHConnectionError: Error {
    case connectionFailed(String)
    case authenticationFailed(String)
    case unknownHost(String)
    case hostKeyMismatch(expected: String, actual: String)
    case timeout
    case notConnected
}

public enum SSHAuthMethod: Sendable {
    case password(SecureBytes)
    case key(path: String, passphrase: SecureBytes?)
}

/// Policy controlling how `SSHAdapter` handles the remote host key.
///
/// - Note: `KnownHostStore` is `@MainActor`-isolated; the enum uses
///   `@unchecked Sendable` because the store is only accessed on
///   `MainActor` inside `TOFUHostKeyDelegate`.
public enum SSHHostKeyPolicy: @unchecked Sendable {
    /// Blindly accept any host key. Used only in tests / debug builds where
    /// connecting to throwaway hosts is acceptable.
    case acceptAnything
    /// Trust-on-first-use: records unknown hosts on first contact via
    /// ``HostKeyValidator`` and rejects fingerprint mismatches.
    case trustOnFirstUse(store: any KnownHostStore)
}

public actor SSHAdapter: RemoteConnection {
    public let id: UUID = UUID()
    public private(set) var state: ConnectionState = .disconnected

    private let host: String
    private let port: Int
    private let username: String
    private let authMethod: SSHAuthMethod
    private let keepAliveInterval: Int
    private let hostKeyPolicy: SSHHostKeyPolicy

    private var sshClient: SSHClient?

    private var stateContinuation: AsyncStream<ConnectionState>.Continuation?
    private var _stateStream: AsyncStream<ConnectionState>?
    private var outputContinuation: AsyncStream<Data>.Continuation?
    private var _outputStream: AsyncStream<Data>?

    private let logger = Logger(label: "com.everyterm.ssh")

    public init(
        host: String,
        port: Int,
        username: String,
        authMethod: SSHAuthMethod,
        keepAliveInterval: Int = 60,
        hostKeyPolicy: SSHHostKeyPolicy = .acceptAnything
    ) {
        self.host = host
        self.port = port
        self.username = username
        self.authMethod = authMethod
        self.keepAliveInterval = keepAliveInterval
        self.hostKeyPolicy = hostKeyPolicy

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

        do {
            let sshAuth = try buildAuthMethod()

            let hostKeyValidator: SSHHostKeyValidator
            switch hostKeyPolicy {
            case .acceptAnything:
                hostKeyValidator = .acceptAnything()
            case .trustOnFirstUse(let store):
                let host = self.host
                let port = self.port
                hostKeyValidator = .custom(
                    TOFUHostKeyDelegate(host: host, port: port, store: store)
                )
            }

            let client = try await SSHClient.connect(
                host: host,
                port: port,
                authenticationMethod: sshAuth,
                hostKeyValidator: hostKeyValidator,
                reconnect: .never
            )

            self.sshClient = client
            state = .connected
            stateContinuation?.yield(.connected)

            logger.info("SSH connected to \(host):\(port)")
        } catch is SSHConnectionError {
            throw SSHConnectionError.connectionFailed("Cannot connect to \(host):\(port)")
        } catch {
            let sshError = SSHConnectionError.connectionFailed("Cannot connect to \(host):\(port)")
            state = .failed(sshError)
            stateContinuation?.yield(.failed(sshError))
            throw sshError
        }
    }

    private func buildAuthMethod() throws -> SSHAuthenticationMethod {
        switch authMethod {
        case .password(let securePassword):
            let passwordString = String(bytes: Array(securePassword), encoding: .utf8) ?? ""
            return .passwordBased(username: username, password: passwordString)

        case .key(let path, let passphrase):
            let expandedPath = (path as NSString).expandingTildeInPath
            let keyURL = URL(fileURLWithPath: expandedPath)
            guard let keyData = try? Data(contentsOf: keyURL),
                  let keyString = String(data: keyData, encoding: .utf8) else {
                throw SSHConnectionError.authenticationFailed("Cannot read key file at \(path)")
            }

            // Derive passphrase data for encrypted keys
            let decryptionKey: Data?
            if let passphrase = passphrase, passphrase.count > 0 {
                let passphraseBytes = Array(passphrase)
                decryptionKey = Data(passphraseBytes)
            } else {
                decryptionKey = nil
            }

            // Detect key type using Citadel's SSHKeyDetection
            do {
                let keyType = try Citadel.SSHKeyDetection.detectPrivateKeyType(from: keyString)

                switch keyType {
                case .ed25519:
                    let privateKey = try Curve25519.Signing.PrivateKey(
                        sshEd25519: keyData,
                        decryptionKey: decryptionKey
                    )
                    return .ed25519(username: username, privateKey: privateKey)

                case .rsa:
                    let privateKey = try Insecure.RSA.PrivateKey(
                        sshRsa: keyData,
                        decryptionKey: decryptionKey
                    )
                    return .rsa(username: username, privateKey: privateKey)

                default:
                    // ECDSA and other key types are not supported by Citadel
                    throw SSHConnectionError.authenticationFailed(
                        "Unsupported key type '\(keyType)' at \(path). Supported types: Ed25519, RSA"
                    )
                }
            } catch is SSHConnectionError {
                throw SSHConnectionError.authenticationFailed("Failed to parse SSH key at \(path)")
            } catch {
                throw SSHConnectionError.authenticationFailed(
                    "Failed to parse SSH key at \(path): \(error.localizedDescription)"
                )
            }
        }
    }

    public func disconnect() async {
        let clientToClose = sshClient
        sshClient = nil
        do {
            try await clientToClose?.close()
        } catch {
            logger.warning("Error closing SSH connection: \(error)")
        }
        state = .disconnected
        stateContinuation?.yield(.disconnected)
    }

    public func send(_ data: Data) async throws {
        guard case .connected = state, let client = sshClient else {
            throw SSHConnectionError.notConnected
        }

        // Open a PTY channel and write data
        // Note: Full PTY session management (persistent channel) is planned for SP-2
        let clientRef = client
        let buffer = ByteBuffer(data: data)
        try await clientRef.executeCommand(
            String(data: data, encoding: .utf8) ?? ""
        )
        _ = buffer // suppress unused warning
    }

    /// Open an SFTP subsystem channel on the existing SSH connection.
    public func openSFTPClient() async throws -> SFTPClient {
        guard case .connected = state, let client = sshClient else {
            throw SSHConnectionError.notConnected
        }
        return try await client.openSFTP()
    }

    /// Execute a command on the remote server
    public func executeCommand(_ command: String) async throws -> Data {
        guard let client = sshClient else {
            throw SSHConnectionError.notConnected
        }

        let clientRef = client
        let output = try await clientRef.executeCommand(command)
        let data = Data(output.readableBytesView)
        outputContinuation?.yield(data)
        return data
    }
}

// MARK: - TOFU Host Key Delegate

/// NIOSSHClientServerAuthenticationDelegate that bridges Citadel's host key
/// callback into our ``HostKeyValidator`` (TOFU model).
///
/// Because ``HostKeyValidator`` and ``KnownHostStore`` are `@MainActor`,
/// the delegate hops to MainActor inside the callback.
internal final class TOFUHostKeyDelegate: NIOSSHClientServerAuthenticationDelegate, @unchecked Sendable {
    private let host: String
    private let port: Int
    private let store: any KnownHostStore

    init(host: String, port: Int, store: any KnownHostStore) {
        self.host = host
        self.port = port
        self.store = store
    }

    func validateHostKey(
        hostKey: NIOSSHPublicKey,
        validationCompletePromise: EventLoopPromise<Void>
    ) {
        let host = self.host
        let port = self.port
        let store = self.store

        // Derive fingerprint: SHA-256 of the serialized public key bytes.
        let openSSHString = String(openSSHPublicKey: hostKey)
        let parts = openSSHString.split(separator: " ", maxSplits: 1)
        let keyType = parts.first.map(String.init) ?? "ssh-unknown"
        let publicKeyBase64 = parts.count > 1 ? String(parts[1]) : ""
        let keyData = Data(base64Encoded: publicKeyBase64) ?? Data()
        let digest = SHA256.hash(data: keyData)
        let fingerprint = Data(digest).base64EncodedString()

        validationCompletePromise.completeWithTask {
            try await MainActor.run {
                let validator = HostKeyValidator(store: store)
                let decision = validator.evaluate(
                    host: host,
                    port: port,
                    keyType: keyType,
                    publicKey: publicKeyBase64,
                    fingerprint: fingerprint
                )
                switch decision {
                case .trustOnFirstUse, .trusted:
                    return
                case .mismatch(let expected, let actual):
                    throw SSHConnectionError.hostKeyMismatch(
                        expected: expected,
                        actual: actual
                    )
                }
            }
        }
    }
}
