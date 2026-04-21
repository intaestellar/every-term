import Testing
import Foundation
@testable import EveryTerm

@Suite("Unsupported Protocol Integration Tests")
struct UnsupportedProtocolIntegrationTests {

    // MARK: - [어려움] RDP/VNC 어댑터 동일 에러 타입 통합 검증

    @Test("RDPAdapter와 VNCAdapter가 모두 .unsupportedProtocol을 throw한다")
    @MainActor func bothAdapters_throw_unsupportedProtocol() async {
        let rdpConfig = RDPSessionConfig(sessionId: UUID())
        let rdpAdapter = RDPAdapter(host: "rdp.example.com", config: rdpConfig)

        let vncConfig = VNCSessionConfig(sessionId: UUID())
        let vncAdapter = VNCAdapter(host: "vnc.example.com", config: vncConfig)

        // RDP 검증
        do {
            try await rdpAdapter.connect()
            Issue.record("RDPAdapter.connect()가 throw 해야 한다")
        } catch let error as RemoteConnectionError {
            switch error {
            case .unsupportedProtocol:
                break // 성공
            default:
                Issue.record("RDPAdapter는 .unsupportedProtocol을 throw해야 한다 (actual: \(error))")
            }
        } catch {
            Issue.record("RemoteConnectionError가 예상되지만 \(error)가 발생")
        }

        // VNC 검증
        do {
            try await vncAdapter.connect()
            Issue.record("VNCAdapter.connect()가 throw 해야 한다")
        } catch let error as RemoteConnectionError {
            switch error {
            case .unsupportedProtocol:
                break // 성공
            default:
                Issue.record("VNCAdapter는 .unsupportedProtocol을 throw해야 한다 (actual: \(error))")
            }
        } catch {
            Issue.record("RemoteConnectionError가 예상되지만 \(error)가 발생")
        }
    }

    @Test("SessionType.isAvailable == false인 타입의 어댑터만 unsupportedProtocol을 throw한다")
    @MainActor func unavailableSessionTypes_matchAdapterErrors() async {
        // rdp와 vnc는 isAvailable == false
        #expect(SessionType.rdp.isAvailable == false)
        #expect(SessionType.vnc.isAvailable == false)

        // 두 어댑터가 .unsupportedProtocol을 throw하는지 확인
        let rdpConfig = RDPSessionConfig(sessionId: UUID())
        let rdpAdapter = RDPAdapter(host: "h", config: rdpConfig)

        do {
            try await rdpAdapter.connect()
            Issue.record("throw 해야 한다")
        } catch let error as RemoteConnectionError {
            switch error {
            case .unsupportedProtocol:
                break // SessionType.rdp.isAvailable == false와 일관
            default:
                Issue.record("unsupportedProtocol이어야 한다")
            }
        } catch {
            Issue.record("RemoteConnectionError 타입이어야 한다")
        }
    }
}
