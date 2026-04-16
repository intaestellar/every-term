import Testing
import Foundation
import Darwin
@testable import EveryTerm

@Suite("TermiosConfigurator Tests")
struct TermiosConfiguratorTests {

    // MARK: - [쉬움] baudRate 매핑

    @Test("baudRate 9600 → termios 적용 성공")
    func baudRate9600_applies() throws {
        var t = Darwin.termios()
        try TermiosConfigurator.applyBaudRate(9600, to: &t)
        // 성공: throw 없음
    }

    @Test("baudRate 115200 → termios 적용 성공")
    func baudRate115200_applies() throws {
        var t = Darwin.termios()
        try TermiosConfigurator.applyBaudRate(115200, to: &t)
    }

    @Test("지원하지 않는 baudRate (12345) → throw")
    func unsupportedBaudRate_throws() {
        var t = Darwin.termios()
        #expect(throws: (any Error).self) {
            try TermiosConfigurator.applyBaudRate(12345, to: &t)
        }
    }

    // MARK: - [보통] dataBits/stopBits/parity/flowControl 매핑

    @Test("dataBits=8, stopBits=1, parity=none → CS8, ~CSTOPB, ~PARENB")
    func standard8N1_flagsCorrect() throws {
        var t = Darwin.termios()
        try TermiosConfigurator.applyFrameFormat(dataBits: 8, stopBits: 1, parity: .none, to: &t)

        // CS8 적용
        #expect((t.c_cflag & tcflag_t(CSIZE)) == tcflag_t(CS8))
        // CSTOPB 해제
        #expect((t.c_cflag & tcflag_t(CSTOPB)) == 0)
        // PARENB 해제
        #expect((t.c_cflag & tcflag_t(PARENB)) == 0)
    }

    @Test("parity even → PARENB set, PARODD clear")
    func parityEven_setsPARENBClearsPARODD() throws {
        var t = Darwin.termios()
        try TermiosConfigurator.applyFrameFormat(dataBits: 8, stopBits: 1, parity: .even, to: &t)

        #expect((t.c_cflag & tcflag_t(PARENB)) != 0)
        #expect((t.c_cflag & tcflag_t(PARODD)) == 0)
    }

    @Test("parity odd → PARENB + PARODD 모두 set")
    func parityOdd_setsPARENBandPARODD() throws {
        var t = Darwin.termios()
        try TermiosConfigurator.applyFrameFormat(dataBits: 8, stopBits: 1, parity: .odd, to: &t)

        #expect((t.c_cflag & tcflag_t(PARENB)) != 0)
        #expect((t.c_cflag & tcflag_t(PARODD)) != 0)
    }

    @Test("stopBits=2 → CSTOPB set")
    func stopBits2_setsCSTOPB() throws {
        var t = Darwin.termios()
        try TermiosConfigurator.applyFrameFormat(dataBits: 8, stopBits: 2, parity: .none, to: &t)
        #expect((t.c_cflag & tcflag_t(CSTOPB)) != 0)
    }

    @Test("flowControl hardware → CRTSCTS set")
    func flowControlHardware_setsCRTSCTS() throws {
        var t = Darwin.termios()
        try TermiosConfigurator.applyFlowControl(.hardware, to: &t)
        #expect((t.c_cflag & tcflag_t(CRTSCTS)) != 0)
    }

    @Test("flowControl software → IXON + IXOFF set")
    func flowControlSoftware_setsIXONAndIXOFF() throws {
        var t = Darwin.termios()
        try TermiosConfigurator.applyFlowControl(.software, to: &t)
        #expect((t.c_iflag & tcflag_t(IXON)) != 0)
        #expect((t.c_iflag & tcflag_t(IXOFF)) != 0)
    }

    @Test("raw mode → ICANON / ECHO / ISIG 클리어")
    func rawMode_clearsCanonEchoIsig() throws {
        var t = Darwin.termios()
        // 시작 전: 플래그 채워두고 raw 로 가면 클리어되는지 확인
        t.c_lflag = tcflag_t(ICANON) | tcflag_t(ECHO) | tcflag_t(ISIG)
        try TermiosConfigurator.applyRawMode(to: &t)

        #expect((t.c_lflag & tcflag_t(ICANON)) == 0)
        #expect((t.c_lflag & tcflag_t(ECHO)) == 0)
        #expect((t.c_lflag & tcflag_t(ISIG)) == 0)
    }
}
