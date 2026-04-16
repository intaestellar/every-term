import Testing
import Foundation
@testable import EveryTerm

@Suite("VNCSessionConfig Model Tests")
struct VNCSessionConfigTests {

    // MARK: - [쉬움] 기본값

    @Test("port 기본값 5900")
    @MainActor func portDefault_is5900() {
        let config = VNCSessionConfig(sessionId: UUID())
        #expect(config.port == 5900)
    }

    @Test("viewOnly 기본값 false")
    @MainActor func viewOnlyDefault_isFalse() {
        let config = VNCSessionConfig(sessionId: UUID())
        #expect(config.viewOnly == false)
    }

    @Test("encodingRaw 기본값이 VNCEncoding.zrle.rawValue 와 일치")
    @MainActor func encodingDefault_isZRLE() {
        let config = VNCSessionConfig(sessionId: UUID())
        #expect(config.encodingRaw == VNCEncoding.zrle.rawValue)
    }

    @Test("scalingModeRaw 기본값은 VNCScalingMode 중 유효한 rawValue")
    @MainActor func scalingModeDefault_isValid() {
        let config = VNCSessionConfig(sessionId: UUID())
        let valid = VNCScalingMode.allCases.map(\.rawValue)
        #expect(valid.contains(config.scalingModeRaw))
    }

    @Test("sshTunnelSessionId 초기값 nil")
    @MainActor func sshTunnelSessionId_defaultNil() {
        let config = VNCSessionConfig(sessionId: UUID())
        #expect(config.sshTunnelSessionId == nil)
    }

    // MARK: - [보통] enum 라운드트립

    @Test("VNCEncoding enum rawValue 라운드트립 (zrle, tight, copyRect, raw)")
    func vncEncodingRawValueRoundTrip() {
        #expect(VNCEncoding(rawValue: VNCEncoding.zrle.rawValue) == .zrle)
        #expect(VNCEncoding(rawValue: VNCEncoding.tight.rawValue) == .tight)
        #expect(VNCEncoding(rawValue: VNCEncoding.copyRect.rawValue) == .copyRect)
        #expect(VNCEncoding(rawValue: VNCEncoding.raw.rawValue) == .raw)

        let allCases = Set(VNCEncoding.allCases)
        #expect(allCases.contains(.zrle))
        #expect(allCases.contains(.tight))
        #expect(allCases.contains(.copyRect))
        #expect(allCases.contains(.raw))
    }

    @Test("VNCScalingMode enum rawValue 라운드트립 (fit, scroll, native)")
    func vncScalingModeRoundTrip() {
        #expect(VNCScalingMode(rawValue: VNCScalingMode.fit.rawValue) == .fit)
        #expect(VNCScalingMode(rawValue: VNCScalingMode.scroll.rawValue) == .scroll)
        #expect(VNCScalingMode(rawValue: VNCScalingMode.native.rawValue) == .native)
    }

    @Test("sshTunnelSessionId 설정 후 값 유지")
    @MainActor func sshTunnelSessionId_persists() {
        let config = VNCSessionConfig(sessionId: UUID())
        let tunnelId = UUID()
        config.sshTunnelSessionId = tunnelId
        #expect(config.sshTunnelSessionId == tunnelId)
    }

    @Test("encodingRaw 변경 후 값 반영")
    @MainActor func encoding_canBeMutated() {
        let config = VNCSessionConfig(sessionId: UUID())
        config.encodingRaw = VNCEncoding.tight.rawValue
        #expect(config.encodingRaw == VNCEncoding.tight.rawValue)
    }

    @Test("sessionId 동일해도 서로 다른 id 유지")
    @MainActor func uniqueIdPerInstance() {
        let sessionId = UUID()
        let c1 = VNCSessionConfig(sessionId: sessionId)
        let c2 = VNCSessionConfig(sessionId: sessionId)
        #expect(c1.id != c2.id)
    }
}
