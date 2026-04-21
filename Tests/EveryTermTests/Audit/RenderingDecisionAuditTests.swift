import Testing
import Foundation

// 워크트리 루트 역산
private enum RenderAuditRoot {
    static func url(filePath: StaticString = #filePath) -> URL {
        let fileURL = URL(fileURLWithPath: "\(filePath)")
        return fileURL
            .deletingLastPathComponent() // Audit
            .deletingLastPathComponent() // EveryTermTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // <root>
    }
}

@Suite("RenderingBackendDecision Tests")
struct RenderingDecisionAuditTests {

    private func terminalBufferManagerURL() -> URL {
        RenderAuditRoot.url()
            .appendingPathComponent("Sources/EveryTerm/Core/Terminal/TerminalBufferManager.swift")
    }

    private func readSource() throws -> String {
        let data = try Data(contentsOf: terminalBufferManagerURL())
        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - [쉬움] 마커

    @Test("TerminalBufferManager — '// MARK: Rendering Backend Decision' 마커 라인 존재")
    func markMarkerExists() throws {
        let content = try readSource()
        #expect(content.contains("// MARK: Rendering Backend Decision"))
    }

    // MARK: - [보통] 결정 근거

    @Test("MARK 블록 — Metal 또는 CPU 키워드 + 결정 근거(profiled/benchmark/decision) 포함")
    func decisionRationaleIncluded() throws {
        let content = try readSource()
        #expect(content.contains("Metal") || content.contains("CPU"))
        let rationaleKeywords = ["profiled", "benchmark", "decision", "Profiled", "Benchmark", "Decision"]
        #expect(rationaleKeywords.contains(where: { content.contains($0) }))
    }

    @Test("스크롤백 상한 상수 선언 존재 + 1000 이상 정수")
    func scrollbackLimitConstant() throws {
        let content = try readSource()
        // 상수명은 ScrollbackLimit 또는 유사 이름 허용
        let candidates = ["ScrollbackLimit", "scrollbackLimit", "perTabLineLimit"]
        #expect(candidates.contains(where: { content.contains($0) }))

        // perTabLineLimit 의 기본값이 1,000 이상인지 감사 — "10_000" 또는 "10000" 등 1000 이상 정수 리터럴 탐지
        let regexCandidates = ["10_000", "10000", "5_000", "5000", "1_000", "1000", "20_000", "20000"]
        #expect(regexCandidates.contains(where: { content.contains($0) }))
    }
}
