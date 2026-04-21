import Testing
import Foundation
@testable import EveryTerm

@Suite("SerialSessionConfig Model Tests")
struct SerialSessionConfigTests {

    // MARK: - [쉬움] 기본값

    @Test("baudRate 기본값은 표준 값 (9600 또는 115200)")
    @MainActor func baudRateDefault_isStandard() {
        let config = SerialSessionConfig(sessionId: UUID())
        #expect(config.baudRate == 9600 || config.baudRate == 115200)
    }

    @Test("dataBits 기본값 8, stopBits 기본값 1")
    @MainActor func dataBitsStopBitsDefaults() {
        let config = SerialSessionConfig(sessionId: UUID())
        #expect(config.dataBits == 8)
        #expect(config.stopBits == 1)
    }

    @Test("parityRaw 기본값 'none'")
    @MainActor func parityDefault_isNone() {
        let config = SerialSessionConfig(sessionId: UUID())
        #expect(config.parityRaw == SerialParity.none.rawValue)
    }

    @Test("flowControlRaw 기본값 'none'")
    @MainActor func flowControlDefault_isNone() {
        let config = SerialSessionConfig(sessionId: UUID())
        #expect(config.flowControlRaw == SerialFlowControl.none.rawValue)
    }

    @Test("devicePath 빈 문자열 초기값")
    @MainActor func devicePathDefault_isEmpty() {
        let config = SerialSessionConfig(sessionId: UUID())
        #expect(config.devicePath == "")
    }

    // MARK: - [보통] enum 라운드트립

    @Test("SerialParity enum rawValue 라운드트립 (none/even/odd)")
    func serialParityRoundTrip() {
        #expect(SerialParity(rawValue: "none") == SerialParity.none)
        #expect(SerialParity(rawValue: "even") == .even)
        #expect(SerialParity(rawValue: "odd") == .odd)

        #expect(SerialParity.none.rawValue == "none")
        #expect(SerialParity.even.rawValue == "even")
        #expect(SerialParity.odd.rawValue == "odd")
    }

    @Test("SerialFlowControl enum rawValue 라운드트립 (none/hardware/software)")
    func serialFlowControlRoundTrip() {
        #expect(SerialFlowControl(rawValue: "none") == SerialFlowControl.none)
        #expect(SerialFlowControl(rawValue: "hardware") == .hardware)
        #expect(SerialFlowControl(rawValue: "software") == .software)

        #expect(SerialFlowControl.none.rawValue == "none")
        #expect(SerialFlowControl.hardware.rawValue == "hardware")
        #expect(SerialFlowControl.software.rawValue == "software")
    }

    @Test("허용 baudRate 집합 검증 (9600/19200/38400/57600/115200)")
    func allowedBaudRates() {
        let allowed: Set<Int> = [9600, 19200, 38400, 57600, 115200]
        for rate in allowed {
            #expect(SerialSessionConfig.isAllowedBaudRate(rate) == true)
        }
        #expect(SerialSessionConfig.isAllowedBaudRate(12345) == false)
        #expect(SerialSessionConfig.isAllowedBaudRate(0) == false)
    }

    @Test("devicePath 변경 후 값 반영")
    @MainActor func devicePath_canBeMutated() {
        let config = SerialSessionConfig(sessionId: UUID())
        config.devicePath = "/dev/tty.usbserial-ABC"
        #expect(config.devicePath == "/dev/tty.usbserial-ABC")
    }

    @Test("모든 필드 라운드트립 (생성 → 설정 → 조회)")
    @MainActor func fullFieldRoundTrip() {
        let config = SerialSessionConfig(sessionId: UUID())
        config.devicePath = "/dev/tty.usbserial-1"
        config.baudRate = 115200
        config.dataBits = 8
        config.stopBits = 1
        config.parityRaw = SerialParity.even.rawValue
        config.flowControlRaw = SerialFlowControl.hardware.rawValue

        #expect(config.devicePath == "/dev/tty.usbserial-1")
        #expect(config.baudRate == 115200)
        #expect(config.dataBits == 8)
        #expect(config.stopBits == 1)
        #expect(config.parityRaw == "even")
        #expect(config.flowControlRaw == "hardware")
    }
}
