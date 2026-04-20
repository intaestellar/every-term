import Testing
import Foundation
@testable import EveryTerm

@Suite("SessionType.isAvailable Tests")
struct SessionTypeTests {

    // MARK: - [쉬움] 개별 isAvailable 검증

    @Test("SessionType.ssh.isAvailable == true")
    func isAvailable_ssh_true() {
        #expect(SessionType.ssh.isAvailable == true)
    }

    @Test("SessionType.local.isAvailable == true")
    func isAvailable_local_true() {
        #expect(SessionType.local.isAvailable == true)
    }

    @Test("SessionType.telnet.isAvailable == true")
    func isAvailable_telnet_true() {
        #expect(SessionType.telnet.isAvailable == true)
    }

    @Test("SessionType.serial.isAvailable == true")
    func isAvailable_serial_true() {
        #expect(SessionType.serial.isAvailable == true)
    }

    @Test("SessionType.rdp.isAvailable == false")
    func isAvailable_rdp_false() {
        #expect(SessionType.rdp.isAvailable == false)
    }

    @Test("SessionType.vnc.isAvailable == false")
    func isAvailable_vnc_false() {
        #expect(SessionType.vnc.isAvailable == false)
    }

    // MARK: - [보통] allCases 전수 검증

    @Test("CaseIterable 순회 시 rdp/vnc만 isAvailable == false")
    func isAvailable_allCases_onlyRDPandVNC_areFalse() {
        let unavailable = SessionType.allCases.filter { !$0.isAvailable }
        #expect(unavailable.count == 2)
        #expect(unavailable.contains(.rdp))
        #expect(unavailable.contains(.vnc))
    }

    // MARK: - [어려움] 통합 — 미지원 프로토콜 세트 완전성

    @Test("미지원 프로토콜 세트가 정확히 {rdp, vnc}인지 검증")
    func unavailableSessionTypes_exactlyRDPandVNC() {
        let unavailable = Set(SessionType.allCases.filter { !$0.isAvailable })
        #expect(unavailable == Set([SessionType.rdp, SessionType.vnc]))
    }
}
