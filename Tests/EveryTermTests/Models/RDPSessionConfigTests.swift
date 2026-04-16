import Testing
import Foundation
@testable import EveryTerm

@Suite("RDPSessionConfig Model Tests")
struct RDPSessionConfigTests {

    // MARK: - [쉬움] 기본값

    @Test("기본값으로 생성 후 id, sessionId UUID 유효성 확인")
    @MainActor func createWithDefaults_generatesValidIds() {
        let sessionId = UUID()
        let config = RDPSessionConfig(sessionId: sessionId)

        #expect(config.sessionId == sessionId)
        // UUID 기본값은 0이 아닌 유효한 UUID여야 한다
        #expect(config.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }

    @Test("colorDepth 기본값은 24 또는 32 중 하나")
    @MainActor func colorDepthDefault_isStandardValue() {
        let config = RDPSessionConfig(sessionId: UUID())
        #expect(config.colorDepth == 24 || config.colorDepth == 32)
    }

    @Test("useNLA 기본값 true")
    @MainActor func useNLADefault_isTrue() {
        let config = RDPSessionConfig(sessionId: UUID())
        #expect(config.useNLA == true)
    }

    @Test("enableClipboard / enableDriveRedirect / enableAudio 기본값 확인")
    @MainActor func featureFlags_defaultValues() {
        let config = RDPSessionConfig(sessionId: UUID())
        // 기본값은 구현체가 결정하되 Bool 타입이어야 한다
        _ = config.enableClipboard
        _ = config.enableDriveRedirect
        _ = config.enableAudio
        // 기본값은 false or true 모두 허용. 단, 드라이브 리다이렉트는 기본 false가 안전
        #expect(config.enableDriveRedirect == false)
    }

    @Test("width / height 초기값 nil (탭 크기 자동 맞춤)")
    @MainActor func dimensionsDefault_isNil() {
        let config = RDPSessionConfig(sessionId: UUID())
        #expect(config.width == nil)
        #expect(config.height == nil)
    }

    // MARK: - [보통] 설정/조회 라운드트립

    @Test("Gateway 필드 설정/조회 라운드트립")
    @MainActor func gatewayFields_roundTrip() {
        let config = RDPSessionConfig(sessionId: UUID())
        config.gatewayHost = "gw.example.com"
        config.gatewayPort = 443
        config.gatewayUsername = "gwuser"

        #expect(config.gatewayHost == "gw.example.com")
        #expect(config.gatewayPort == 443)
        #expect(config.gatewayUsername == "gwuser")
    }

    @Test("sharedFolderPath 설정 후 값 유지")
    @MainActor func sharedFolderPath_persists() {
        let config = RDPSessionConfig(sessionId: UUID())
        config.sharedFolderPath = "/Users/me/Shared"
        #expect(config.sharedFolderPath == "/Users/me/Shared")
    }

    @Test("sessionId 가 같더라도 id 는 서로 다른 UUID를 가진다")
    @MainActor func twoConfigs_haveUniqueIds() {
        let sessionId = UUID()
        let c1 = RDPSessionConfig(sessionId: sessionId)
        let c2 = RDPSessionConfig(sessionId: sessionId)
        #expect(c1.id != c2.id)
    }

    @Test("colorDepth 변경 후 값 반영")
    @MainActor func colorDepth_canBeMutated() {
        let config = RDPSessionConfig(sessionId: UUID())
        config.colorDepth = 16
        #expect(config.colorDepth == 16)
    }

    @Test("domain 필드 설정/유지")
    @MainActor func domain_persists() {
        let config = RDPSessionConfig(sessionId: UUID())
        config.domain = "CORP"
        #expect(config.domain == "CORP")
    }
}
