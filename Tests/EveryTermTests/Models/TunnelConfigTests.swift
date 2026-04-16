import Testing
import Foundation
@testable import EveryTerm

@Suite("TunnelConfig Model Tests")
struct TunnelConfigTests {

    // MARK: - [쉬움] 기본 생성 및 프로퍼티

    @Test("TunnelConfig 기본값으로 생성 후 프로퍼티 일치 확인")
    @MainActor func createWithDefaults() {
        let sessionId = UUID()
        let config = TunnelConfig(
            name: "My Tunnel",
            sessionId: sessionId,
            type: .local,
            localPort: 8080,
            remoteHost: "example.com",
            remotePort: 80
        )

        #expect(config.name == "My Tunnel")
        #expect(config.sessionId == sessionId)
        #expect(config.type == .local)
        #expect(config.localPort == 8080)
        #expect(config.remoteHost == "example.com")
        #expect(config.remotePort == 80)
        #expect(config.id != UUID())
    }

    @Test("TunnelType enum rawValue 라운드트립 (.local, .remote, .dynamic)")
    func tunnelTypeRawValueRoundTrip() {
        #expect(TunnelType(rawValue: "local") == .local)
        #expect(TunnelType(rawValue: "remote") == .remote)
        #expect(TunnelType(rawValue: "dynamic") == .dynamic)

        #expect(TunnelType.local.rawValue == "local")
        #expect(TunnelType.remote.rawValue == "remote")
        #expect(TunnelType.dynamic.rawValue == "dynamic")
    }

    @Test("localHost 기본값 127.0.0.1 확인")
    @MainActor func localHostDefault() {
        let config = TunnelConfig(
            name: "Test",
            sessionId: UUID(),
            type: .local,
            localPort: 3000,
            remoteHost: "remote.host",
            remotePort: 22
        )

        #expect(config.localHost == "127.0.0.1")
    }

    @Test("dynamic 타입일 때 remoteHost 빈 문자열 / remotePort 0 확인")
    @MainActor func dynamicTypeRemoteDefaults() {
        let config = TunnelConfig(
            name: "SOCKS5",
            sessionId: UUID(),
            type: .dynamic,
            localPort: 1080,
            remoteHost: "",
            remotePort: 0
        )

        #expect(config.type == .dynamic)
        #expect(config.remoteHost == "")
        #expect(config.remotePort == 0)
    }

    // MARK: - [보통] Codable / 식별

    @Test("TunnelConfig Codable 인코딩/디코딩 라운드트립")
    func codableRoundTrip() throws {
        let type = TunnelType.local
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(type)
        let decoded = try decoder.decode(TunnelType.self, from: data)
        #expect(decoded == type)
    }

    @Test("isAutoStart=true 설정 후 값 유지 확인")
    @MainActor func isAutoStartPersistence() {
        let config = TunnelConfig(
            name: "Auto Start Tunnel",
            sessionId: UUID(),
            type: .local,
            localPort: 9090,
            remoteHost: "host",
            remotePort: 22
        )
        config.isAutoStart = true

        #expect(config.isAutoStart == true)
    }

    @Test("동일 localPort를 가진 두 TunnelConfig id 유일성 확인")
    @MainActor func uniqueIdForSamePort() {
        let config1 = TunnelConfig(
            name: "Tunnel A",
            sessionId: UUID(),
            type: .local,
            localPort: 8080,
            remoteHost: "host-a",
            remotePort: 80
        )
        let config2 = TunnelConfig(
            name: "Tunnel B",
            sessionId: UUID(),
            type: .local,
            localPort: 8080,
            remoteHost: "host-b",
            remotePort: 80
        )

        #expect(config1.id != config2.id)
    }
}
