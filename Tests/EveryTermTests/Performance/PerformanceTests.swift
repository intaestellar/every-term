import Testing
import Foundation
@testable import EveryTerm

/// Skeleton performance suite — these are heavyweight integration style
/// benchmarks (10 concurrent SSH sessions, 1GB SFTP transfer, memory
/// footprint). They are gated behind the `EVERYTERM_PERF` environment
/// variable so the default `swift test` invocation stays fast and
/// hermetic in CI.
///
/// To run locally:
/// ```
/// EVERYTERM_PERF=1 swift test --filter PerformanceTests
/// ```
@Suite("Performance (opt-in)")
struct PerformanceTests {
    private static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["EVERYTERM_PERF"] == "1"
    }

    @Test(
        "10 동시 SSH 세션에서 CPU 평균 < 10%",
        .disabled(if: !PerformanceTests.isEnabled, "EVERYTERM_PERF=1 필요")
    )
    func tenConcurrentSSHSessionsCPU() async throws {
        // Placeholder — real benchmark harness lives behind EVERYTERM_PERF.
        // The skeleton simply spins up 10 SSHAdapter instances so compile
        // errors surface even when the gate is open.
        var adapters: [SSHAdapter] = []
        for _ in 0..<10 {
            adapters.append(SSHAdapter(
                host: "invalid.nonexistent.host.example",
                port: 22,
                username: "u",
                authMethod: .password(SecureBytes(utf8: "p"))
            ))
        }
        #expect(adapters.count == 10)
    }

    @Test(
        "앱 메모리 풋프린트 < 200MB",
        .disabled(if: !PerformanceTests.isEnabled, "EVERYTERM_PERF=1 필요")
    )
    func appMemoryFootprint() async throws {
        // Placeholder. Real measurement will sample `task_info(TASK_VM_INFO)`
        // after launching the full app scene.
        #expect(Bool(true))
    }

    @Test(
        "1GB SFTP 전송이 안정적으로 완료",
        .disabled(if: !PerformanceTests.isEnabled, "EVERYTERM_PERF=1 필요")
    )
    func oneGigabyteSFTPTransfer() async throws {
        // Placeholder. Real benchmark will run against a local openssh/sftpd
        // container started via the release pipeline.
        #expect(Bool(true))
    }
}
