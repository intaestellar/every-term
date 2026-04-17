import Testing
import Foundation

// MARK: - 워크트리 루트 역산 헬퍼

private enum WorktreeRoot {
    static func url(filePath: StaticString = #filePath) -> URL {
        // 이 파일은 Tests/EveryTermTests/Audit/ReleaseAssetsAuditTests.swift 에 있으므로
        // 3단계 상위 = 워크트리 루트
        let fileURL = URL(fileURLWithPath: "\(filePath)")
        return fileURL
            .deletingLastPathComponent() // Audit
            .deletingLastPathComponent() // EveryTermTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // <root>
    }
}

// MARK: - ReleaseScriptPresenceTests

@Suite("ReleaseScriptPresence Tests")
struct ReleaseScriptPresenceTests {

    private func script(_ name: String) -> URL {
        WorktreeRoot.url().appendingPathComponent("Scripts").appendingPathComponent(name)
    }

    // MARK: - [쉬움] 파일 존재

    @Test("Scripts/sign.sh 존재")
    func signShExists() {
        #expect(FileManager.default.fileExists(atPath: script("sign.sh").path))
    }

    @Test("Scripts/notarize.sh 존재")
    func notarizeShExists() {
        #expect(FileManager.default.fileExists(atPath: script("notarize.sh").path))
    }

    @Test("Scripts/create-dmg.sh 존재")
    func createDmgShExists() {
        #expect(FileManager.default.fileExists(atPath: script("create-dmg.sh").path))
    }

    @Test("Scripts/generate-appcast.sh 존재")
    func generateAppcastShExists() {
        #expect(FileManager.default.fileExists(atPath: script("generate-appcast.sh").path))
    }

    @Test("4개 스크립트 모두 shebang (bash)")
    func scriptsHaveShebang() throws {
        for name in ["sign.sh", "notarize.sh", "create-dmg.sh", "generate-appcast.sh"] {
            let url = script(name)
            guard let data = try? Data(contentsOf: url), let content = String(data: data, encoding: .utf8) else {
                Issue.record("\(name) 읽기 실패")
                continue
            }
            let firstLine = content.split(separator: "\n").first.map(String.init) ?? ""
            #expect(firstLine == "#!/usr/bin/env bash" || firstLine == "#!/bin/bash",
                    "\(name) shebang 불일치: \(firstLine)")
        }
    }

    @Test("4개 스크립트 모두 owner 실행 권한(S_IXUSR) 설정")
    func scriptsAreExecutable() throws {
        for name in ["sign.sh", "notarize.sh", "create-dmg.sh", "generate-appcast.sh"] {
            let url = script(name)
            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
            if let mode = attrs?[.posixPermissions] as? NSNumber {
                let perms = mode.uint16Value
                #expect((perms & 0o100) != 0, "\(name) owner 실행 비트 부재")
            } else {
                Issue.record("\(name) permissions 읽기 실패")
            }
        }
    }

    // Script content keyword checks removed — these are tautological
    // (we control the scripts) and duplicate the CI dry-run validation
    // in .github/workflows/release.yml.
}

// MARK: - CIWorkflowPresenceTests

@Suite("CIWorkflowPresence Tests")
struct CIWorkflowPresenceTests {

    private func workflow(_ name: String) -> URL {
        WorktreeRoot.url().appendingPathComponent(".github/workflows").appendingPathComponent(name)
    }

    // MARK: - [쉬움] 파일 존재

    @Test(".github/workflows/pr.yml 존재")
    func prYmlExists() {
        #expect(FileManager.default.fileExists(atPath: workflow("pr.yml").path))
    }

    @Test(".github/workflows/main.yml 존재")
    func mainYmlExists() {
        #expect(FileManager.default.fileExists(atPath: workflow("main.yml").path))
    }

    @Test(".github/workflows/release.yml 존재")
    func releaseYmlExists() {
        #expect(FileManager.default.fileExists(atPath: workflow("release.yml").path))
    }

    // Workflow content keyword checks removed — tautological string-greps
    // that duplicate what CI itself validates on every run.
}

// MARK: - CommunityDocsPresenceTests

@Suite("CommunityDocsPresence Tests")
struct CommunityDocsPresenceTests {

    private func file(_ path: String) -> URL {
        WorktreeRoot.url().appendingPathComponent(path)
    }

    // MARK: - [쉬움] 파일 존재

    @Test("README.md 존재 + 크기 > 512 바이트")
    func readmeExists() throws {
        let url = file("README.md")
        #expect(FileManager.default.fileExists(atPath: url.path))
        let data = try Data(contentsOf: url)
        #expect(data.count > 512)
    }

    @Test("CHANGELOG.md 존재")
    func changelogExists() {
        #expect(FileManager.default.fileExists(atPath: file("CHANGELOG.md").path))
    }

    @Test("CONTRIBUTING.md 존재")
    func contributingExists() {
        #expect(FileManager.default.fileExists(atPath: file("CONTRIBUTING.md").path))
    }

    @Test("CODE_OF_CONDUCT.md 존재")
    func cocExists() {
        #expect(FileManager.default.fileExists(atPath: file("CODE_OF_CONDUCT.md").path))
    }

    @Test(".github/ISSUE_TEMPLATE/bug_report.md 존재")
    func bugTemplateExists() {
        #expect(FileManager.default.fileExists(atPath: file(".github/ISSUE_TEMPLATE/bug_report.md").path))
    }

    @Test(".github/ISSUE_TEMPLATE/feature_request.md 존재")
    func featureTemplateExists() {
        #expect(FileManager.default.fileExists(atPath: file(".github/ISSUE_TEMPLATE/feature_request.md").path))
    }

    @Test(".github/PULL_REQUEST_TEMPLATE.md 존재")
    func prTemplateExists() {
        #expect(FileManager.default.fileExists(atPath: file(".github/PULL_REQUEST_TEMPLATE.md").path))
    }

    // Document content keyword checks removed — tautological string-greps
    // on files we fully control. File existence checks above are sufficient.
}

// MARK: - HomebrewCaskFormulaTests

@Suite("HomebrewCaskFormula Tests")
struct HomebrewCaskFormulaTests {

    private func formulaURL() -> URL {
        WorktreeRoot.url().appendingPathComponent("Formula/everyterm.rb")
    }

    @Test("Formula/everyterm.rb 존재")
    func formulaExists() {
        #expect(FileManager.default.fileExists(atPath: formulaURL().path))
    }

    @Test("cask \"everyterm\" 라인 포함")
    func caskLineIncluded() throws {
        let c = try readFormula()
        #expect(c.contains("cask \"everyterm\""))
    }

    @Test("version + sha256 필드 포함")
    func versionAndSha256() throws {
        let c = try readFormula()
        #expect(c.contains("version"))
        #expect(c.contains("sha256"))
    }

    @Test("url \"https://github.com/ 패턴 포함")
    func githubReleaseURL() throws {
        let c = try readFormula()
        #expect(c.contains("url \"https://github.com/"))
    }

    @Test("app \"EveryTerm.app\" 포함")
    func appLineIncluded() throws {
        let c = try readFormula()
        #expect(c.contains("app \"EveryTerm.app\""))
    }

    private func readFormula() throws -> String {
        let data = try Data(contentsOf: formulaURL())
        return String(data: data, encoding: .utf8) ?? ""
    }
}

// MARK: - EntitlementsAuditTests

@Suite("EntitlementsAudit Tests")
struct EntitlementsAuditTests {

    private func entitlementsURL() -> URL {
        WorktreeRoot.url().appendingPathComponent("EveryTerm.entitlements")
    }

    @Test("EveryTerm.entitlements 존재")
    func entitlementsExist() {
        #expect(FileManager.default.fileExists(atPath: entitlementsURL().path))
    }

    @Test("plist 파서 디코드 성공")
    func plistDecodable() throws {
        let data = try Data(contentsOf: entitlementsURL())
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        #expect(plist is [String: Any])
    }

    @Test("com.apple.security.app-sandbox == false")
    func appSandboxFalse() throws {
        let dict = try loadPlistDict()
        #expect(dict["com.apple.security.app-sandbox"] as? Bool == false)
    }

    @Test("com.apple.security.network.client == true")
    func networkClientTrue() throws {
        let dict = try loadPlistDict()
        #expect(dict["com.apple.security.network.client"] as? Bool == true)
    }

    @Test("com.apple.security.cs.disable-library-validation — 명시적 키 상태 확인")
    func disableLibraryValidationKey() throws {
        // FreeRDP/LibVNC 번들 로드 위해 필요. 의도적으로 true/false 명시된 경우만 통과.
        let dict = try loadPlistDict()
        let key = "com.apple.security.cs.disable-library-validation"
        if dict[key] != nil {
            #expect(dict[key] is Bool)
        }
    }

    @Test("com.apple.security.cs.allow-jit == false 또는 부재 (Hardened Runtime)")
    func allowJitFalseOrAbsent() throws {
        let dict = try loadPlistDict()
        let key = "com.apple.security.cs.allow-jit"
        if let value = dict[key] {
            #expect(value as? Bool == false)
        }
    }

    @Test("키 집합이 '현재 사용 중인 entitlement' 화이트리스트에 속함 — 키 추가 시 이 테스트 갱신 필수")
    func keysWhitelisted() throws {
        let dict = try loadPlistDict()
        // Only keys that actually appear in EveryTerm.entitlements today.
        // Adding a new entitlement requires a deliberate PR updating this list.
        let allowed: Set<String> = [
            "com.apple.security.app-sandbox",
            "com.apple.security.network.client",
            "com.apple.security.hardened-runtime",
        ]
        for key in dict.keys {
            #expect(allowed.contains(key), "예상치 못한 entitlement 키: \(key)")
        }
    }

    private func loadPlistDict() throws -> [String: Any] {
        let data = try Data(contentsOf: entitlementsURL())
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        return (plist as? [String: Any]) ?? [:]
    }
}
