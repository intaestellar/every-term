import Testing
import Foundation
@testable import EveryTerm

@Suite("UpdateConfiguration Tests")
struct UpdateConfigurationTests {

    // MARK: - [쉬움] 기본값

    @Test("UpdateConfiguration.default — feedURL 이 HTTPS 스킴")
    func defaultFeedURLHTTPS() {
        let config = UpdateConfiguration.default
        #expect(config.feedURL.scheme == "https")
    }

    @Test("feedURL 호스트에 'github' 또는 프로젝트 도메인 포함")
    func feedURLHostKeyword() {
        let config = UpdateConfiguration.default
        let host = config.feedURL.host ?? ""
        #expect(host.contains("github") || host.contains("everyterm"))
    }

    @Test("automaticCheckEnabled 기본값 true")
    func defaultAutoCheck() {
        let config = UpdateConfiguration.default
        #expect(config.automaticCheckEnabled == true)
    }

    @Test("checkInterval 기본값 86400 (24시간)")
    func defaultCheckInterval() {
        let config = UpdateConfiguration.default
        #expect(config.checkInterval == 86400)
    }

    // MARK: - [보통] 클램프 / 직렬화

    @Test("checkInterval 0 이하 주입 시 이니셜라이저에서 기본값으로 클램프")
    func clampNonPositiveInterval() {
        let config = UpdateConfiguration(
            feedURL: URL(string: "https://example.com/appcast.xml")!,
            automaticCheckEnabled: true,
            checkInterval: 0,
            publicEDKey: "test-key"
        )
        #expect(config.checkInterval > 0)
    }

    @Test("publicEDKey 기본값은 빈 문자열 (릴리스 시 generate-appcast.sh 가 주입)")
    func publicEDKeyDefaultIsEmpty() {
        let config = UpdateConfiguration.default
        #expect(config.publicEDKey.isEmpty, "기본 publicEDKey 는 placeholder 가 아닌 빈 문자열이어야 합니다")
    }

    @Test("publicEDKey 가 A-반복 placeholder 가 아님")
    func publicEDKeyNotPlaceholder() {
        let config = UpdateConfiguration.default
        let allAs = String(repeating: "A", count: 44)
        #expect(config.publicEDKey != allAs, "publicEDKey 가 placeholder 값이면 안 됩니다")
    }

    @Test("Codable 라운드트립: JSON encode/decode 모든 필드 유지")
    func codableRoundTrip() throws {
        let original = UpdateConfiguration.default
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(UpdateConfiguration.self, from: data)
        #expect(decoded.feedURL == original.feedURL)
        #expect(decoded.automaticCheckEnabled == original.automaticCheckEnabled)
        #expect(decoded.checkInterval == original.checkInterval)
        #expect(decoded.publicEDKey == original.publicEDKey)
    }

    @Test("Sendable 준수 (컴파일)")
    func sendableConformance() {
        func requireSendable<T: Sendable>(_ t: T.Type) {}
        requireSendable(UpdateConfiguration.self)
    }
}
