import Testing
import Foundation
@testable import EveryTerm

@Suite("SerialPortEnumerator Tests")
struct SerialPortEnumeratorTests {

    // MARK: - [쉬움] SerialPortInfo 값 타입

    @Test("SerialPortInfo 초기화 및 필드 저장")
    func serialPortInfoInitialization() {
        let info = SerialPortInfo(
            devicePath: "/dev/tty.usbserial-1",
            friendlyName: "FTDI USB-Serial",
            vendorId: 0x0403,
            productId: 0x6001
        )

        #expect(info.devicePath == "/dev/tty.usbserial-1")
        #expect(info.friendlyName == "FTDI USB-Serial")
        #expect(info.vendorId == 0x0403)
        #expect(info.productId == 0x6001)
    }

    @Test("SerialPortInfo 는 vendorId / productId 가 nil 이어도 생성 가능")
    func serialPortInfo_allowsNilIds() {
        let info = SerialPortInfo(
            devicePath: "/dev/tty.Bluetooth-Incoming-Port",
            friendlyName: "Bluetooth",
            vendorId: nil,
            productId: nil
        )
        #expect(info.vendorId == nil)
        #expect(info.productId == nil)
    }

    // MARK: - [보통] 열거 / 중복 제거

    @Test("빈 목록 입력 → 빈 배열 반환 (dedupe)")
    func deduplicate_emptyInput() {
        let enumerator = SerialPortEnumerator()
        let result = enumerator.deduplicate([])
        #expect(result.isEmpty)
    }

    @Test("중복 devicePath 입력 → 중복 제거")
    func deduplicate_removesDuplicates() {
        let enumerator = SerialPortEnumerator()
        let a = SerialPortInfo(devicePath: "/dev/tty.usb-1", friendlyName: "A", vendorId: nil, productId: nil)
        let dup = SerialPortInfo(devicePath: "/dev/tty.usb-1", friendlyName: "A-dup", vendorId: nil, productId: nil)
        let b = SerialPortInfo(devicePath: "/dev/tty.usb-2", friendlyName: "B", vendorId: nil, productId: nil)

        let result = enumerator.deduplicate([a, dup, b])
        #expect(result.count == 2)
        let paths = Set(result.map(\.devicePath))
        #expect(paths == Set(["/dev/tty.usb-1", "/dev/tty.usb-2"]))
    }

    @Test("enumeratePorts() 호출은 비동기적으로 [SerialPortInfo] 반환 (환경 독립)")
    func enumeratePorts_returnsArray() async {
        let enumerator = SerialPortEnumerator()
        let ports = await enumerator.enumeratePorts()
        // 실제 장치 유무와 무관하게 배열 타입 반환만 확인
        #expect(ports.count >= 0)
    }
}
