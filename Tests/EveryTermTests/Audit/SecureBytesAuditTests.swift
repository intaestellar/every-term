import Testing
import Foundation

// 워크트리 루트 역산
private enum SecureAuditRoot {
    static func url(filePath: StaticString = #filePath) -> URL {
        let fileURL = URL(fileURLWithPath: "\(filePath)")
        return fileURL
            .deletingLastPathComponent() // Audit
            .deletingLastPathComponent() // EveryTermTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // <root>
    }
}

@Suite("SecureBytesAudit Tests")
struct SecureBytesAuditTests {

    private func sourcesRoot() -> URL {
        SecureAuditRoot.url().appendingPathComponent("Sources/EveryTerm")
    }

    private func readFile(_ relativePath: String) throws -> String? {
        let url = SecureAuditRoot.url().appendingPathComponent(relativePath)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return String(data: data, encoding: .utf8)
    }

    // MARK: - [보통] 정적 감사

    @Test("Models/Session.swift — password: String 필드 부재")
    func sessionNoPlainPassword() throws {
        guard let content = try readFile("Sources/EveryTerm/Models/Session.swift") else {
            Issue.record("Session.swift 가 존재하지 않음 — 사전조건 실패")
            return
        }
        #expect(content.contains("password: String") == false)
        #expect(content.contains("var password: String") == false)
    }

    @Test("Models/RDPSessionConfig.swift — password: String 필드 부재")
    func rdpNoPlainPassword() throws {
        guard let content = try readFile("Sources/EveryTerm/Models/RDPSessionConfig.swift") else {
            Issue.record("RDPSessionConfig.swift 가 존재하지 않음 — 사전조건 실패")
            return
        }
        #expect(content.contains("password: String") == false)
        #expect(content.contains("var password: String") == false)
    }

    @Test("Models/VNCSessionConfig.swift — password: String 필드 부재")
    func vncNoPlainPassword() throws {
        guard let content = try readFile("Sources/EveryTerm/Models/VNCSessionConfig.swift") else {
            Issue.record("VNCSessionConfig.swift 가 존재하지 않음 — 사전조건 실패")
            return
        }
        #expect(content.contains("password: String") == false)
        #expect(content.contains("var password: String") == false)
    }

    @Test("Core/SSH/ 하위 파일들 — passphrase: String 평문 필드 부재")
    func sshNoPlainPassphrase() throws {
        let sshDir = sourcesRoot().appendingPathComponent("Core/SSH")
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: sshDir.path) else {
            Issue.record("Core/SSH 디렉토리 없음")
            return
        }
        for file in files where file.hasSuffix(".swift") {
            let url = sshDir.appendingPathComponent(file)
            let data = try Data(contentsOf: url)
            let content = String(data: data, encoding: .utf8) ?? ""
            #expect(content.contains("passphrase: String") == false,
                    "\(file) 에 passphrase: String 평문 필드 존재")
            #expect(content.contains("var passphrase: String") == false,
                    "\(file) 에 var passphrase: String 평문 필드 존재")
        }
    }

    @Test("Logger / os_log / print — 자격증명 식별자 interpolation 부재")
    func noCredentialLogging() throws {
        let sources = sourcesRoot()
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: sources.path) else {
            Issue.record("Sources enumerator 생성 실패")
            return
        }
        let forbiddenInterpolations: [String] = [
            "\\(password",
            "\\(passphrase",
            "\\(privateKey",
        ]
        let logCallPatterns: [String] = [
            "os_log",
            "Logger",
            "logger.",
            "print(",
            "AppLogger",
        ]
        while let rel = enumerator.nextObject() as? String {
            guard rel.hasSuffix(".swift") else { continue }
            let url = sources.appendingPathComponent(rel)
            guard let data = try? Data(contentsOf: url),
                  let content = String(data: data, encoding: .utf8) else { continue }
            let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
            for rawLine in lines {
                let line = String(rawLine)
                if line.contains("// audit:allow") { continue }
                let hasLogCall = logCallPatterns.contains(where: { line.contains($0) })
                guard hasLogCall else { continue }
                for forbidden in forbiddenInterpolations {
                    #expect(line.contains(forbidden) == false,
                            "\(rel) 로그 라인에 자격증명 interpolation: \(line)")
                }
            }
        }
    }

    @Test("감사 대상 Sources 경로 사전조건 — 디렉토리 실존 확인")
    func sourcesPathPrecondition() {
        let root = sourcesRoot()
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: root.path, isDirectory: &isDir)
        #expect(exists == true)
        #expect(isDir.boolValue == true)
    }
}
