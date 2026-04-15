import Foundation
#if canImport(AppKit)
import AppKit
#endif

public enum SSHKeyType: String, Sendable {
    case rsa
    case ed25519
    case ecdsa
}

public struct SSHKeyInfo: Sendable {
    public let type: SSHKeyType
    public let data: String
    public let comment: String

    public init(type: SSHKeyType, data: String, comment: String) {
        self.type = type
        self.data = data
        self.comment = comment
    }
}

public struct SSHKeyGenerationResult: Sendable {
    public let privateKeyPath: String
    public let publicKeyPath: String

    public init(privateKeyPath: String, publicKeyPath: String) {
        self.privateKeyPath = privateKeyPath
        self.publicKeyPath = publicKeyPath
    }
}

public enum SSHKeyError: Error {
    case invalidKeyFormat
    case keyAlreadyExists(name: String)
    case generationFailed(String)
}

public struct SSHKeyManager: Sendable {
    public init() {}

    public func parsePublicKey(_ content: String) throws -> SSHKeyInfo {
        let parts = content.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ", maxSplits: 2)
        guard parts.count >= 2 else {
            throw SSHKeyError.invalidKeyFormat
        }

        let typeStr = String(parts[0])
        let data = String(parts[1])
        let comment = parts.count > 2 ? String(parts[2]) : ""

        let keyType: SSHKeyType
        switch typeStr {
        case "ssh-rsa":
            keyType = .rsa
        case "ssh-ed25519":
            keyType = .ed25519
        case let s where s.hasPrefix("ecdsa-"):
            keyType = .ecdsa
        default:
            throw SSHKeyError.invalidKeyFormat
        }

        return SSHKeyInfo(type: keyType, data: data, comment: comment)
    }

    public func listKeys() async throws -> [SSHKeyInfo] {
        let sshDir = NSHomeDirectory() + "/.ssh"
        let fm = FileManager.default

        guard fm.fileExists(atPath: sshDir) else {
            return []
        }

        let contents = try fm.contentsOfDirectory(atPath: sshDir)
        var keys: [SSHKeyInfo] = []

        for file in contents where file.hasSuffix(".pub") {
            let path = sshDir + "/" + file
            if let content = try? String(contentsOfFile: path, encoding: .utf8) {
                if let keyInfo = try? parsePublicKey(content) {
                    keys.append(keyInfo)
                }
            }
        }

        return keys
    }

    public func generateKey(
        type: SSHKeyType,
        bits: Int? = nil,
        name: String,
        passphrase: SecureBytes?
    ) async throws -> SSHKeyGenerationResult {
        let sshDir = NSHomeDirectory() + "/.ssh"
        let privateKeyPath = sshDir + "/" + name
        let publicKeyPath = privateKeyPath + ".pub"

        let fm = FileManager.default

        // Check if key already exists
        if fm.fileExists(atPath: privateKeyPath) || fm.fileExists(atPath: publicKeyPath) {
            throw SSHKeyError.keyAlreadyExists(name: name)
        }

        // Ensure .ssh directory exists
        if !fm.fileExists(atPath: sshDir) {
            try fm.createDirectory(atPath: sshDir, withIntermediateDirectories: true)
        }

        // Build ssh-keygen command
        let keyTypeArg: String
        switch type {
        case .rsa:
            keyTypeArg = "rsa"
        case .ed25519:
            keyTypeArg = "ed25519"
        case .ecdsa:
            keyTypeArg = "ecdsa"
        }

        let passphraseStr: String
        if let passphrase = passphrase, passphrase.count > 0 {
            passphraseStr = String(bytes: Array(passphrase), encoding: .utf8) ?? ""
        } else {
            passphraseStr = ""
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh-keygen")
        var args = ["-t", keyTypeArg, "-f", privateKeyPath, "-q"]
        if let bits = bits, (type == .rsa || type == .ecdsa) {
            let bitsValue: Int
            if type == .ecdsa {
                // ECDSA uses specific bit sizes
                bitsValue = bits <= 256 ? 256 : (bits <= 384 ? 384 : 521)
            } else {
                bitsValue = bits
            }
            args += ["-b", String(bitsValue)]
        }
        process.arguments = args

        // Pass passphrase via stdin pipe instead of process arguments
        // to avoid exposing it in `ps` output
        let inputPipe = Pipe()
        process.standardInput = inputPipe

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()

        // ssh-keygen prompts for passphrase twice (enter + confirm)
        let passphraseData = Data((passphraseStr + "\n" + passphraseStr + "\n").utf8)
        inputPipe.fileHandleForWriting.write(passphraseData)
        inputPipe.fileHandleForWriting.closeFile()

        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw SSHKeyError.generationFailed("ssh-keygen exited with status \(process.terminationStatus)")
        }

        // Store passphrase in keychain if provided
        if let passphrase = passphrase, passphrase.count > 0 {
            let keychain = KeychainManager()
            try await keychain.save(password: passphrase, forKey: name)
        }

        return SSHKeyGenerationResult(
            privateKeyPath: privateKeyPath,
            publicKeyPath: publicKeyPath
        )
    }

    /// Copy public key content to the system clipboard
    @MainActor
    public func copyPublicKeyToClipboard(_ publicKeyPath: String) throws -> Bool {
        let content = try String(contentsOfFile: publicKeyPath, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        #if canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setString(content, forType: .string)
        #else
        return false
        #endif
    }

    /// Deploy public key to a remote server's authorized_keys via SSH
    /// Uses stdin pipe to avoid shell injection — public key content is never interpolated into shell commands.
    public func deployPublicKey(
        publicKeyPath: String,
        host: String,
        port: Int = 22,
        username: String
    ) async throws {
        let expandedPath = (publicKeyPath as NSString).expandingTildeInPath

        guard FileManager.default.fileExists(atPath: expandedPath) else {
            throw SSHKeyError.generationFailed("Public key not found at \(publicKeyPath)")
        }

        // Validate hostname: only allow alphanumeric, dots, hyphens, and colons (IPv6)
        let allowedHostChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: ".-:[]"))
        guard host.unicodeScalars.allSatisfy({ allowedHostChars.contains($0) }), !host.isEmpty else {
            throw SSHKeyError.generationFailed("Invalid hostname: \(host)")
        }

        let publicKeyContent = try String(contentsOfFile: expandedPath, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Pass public key via stdin to avoid shell injection
        let remoteCommand = "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
        process.arguments = [
            "-p", String(port),
            "\(username)@\(host)",
            remoteCommand
        ]

        // Pipe public key content via stdin instead of embedding in shell command
        let inputPipe = Pipe()
        process.standardInput = inputPipe

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()

        let keyData = Data((publicKeyContent + "\n").utf8)
        inputPipe.fileHandleForWriting.write(keyData)
        inputPipe.fileHandleForWriting.closeFile()

        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? "Unknown error"
            throw SSHKeyError.generationFailed("Failed to deploy key: \(output)")
        }
    }

    /// Build shell command for deploying a public key to a remote server's authorized_keys
    @available(*, deprecated, message: "Use deployPublicKey() which passes the key via stdin to avoid shell injection")
    public func buildDeployCommand(publicKey: String) -> String {
        let escapedKey = publicKey
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "'\\''")
        return "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '\(escapedKey)' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
    }
}
