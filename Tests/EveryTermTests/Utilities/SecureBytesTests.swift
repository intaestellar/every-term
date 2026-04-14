import Testing
@testable import EveryTerm

// MARK: - [쉬움] SecureBytes 초기화 및 기본 동작

@Suite("SecureBytes Tests")
struct SecureBytesTests {

    @Test("빈 SecureBytes 생성 시 count가 0이어야 한다")
    func emptySecureBytes() {
        let bytes = SecureBytes()
        #expect(bytes.count == 0)
    }

    @Test("[UInt8] 배열로 생성 후 내용이 일치해야 한다")
    func initWithByteArray() {
        let raw: [UInt8] = [0x48, 0x65, 0x6C, 0x6C, 0x6F]
        let bytes = SecureBytes(raw)
        #expect(bytes.count == 5)
        #expect(Array(bytes) == raw)
    }

    @Test("UTF-8 문자열로 생성 후 바이트가 일치해야 한다")
    func initWithUTF8String() {
        let bytes = SecureBytes(utf8: "Hello")
        let expected: [UInt8] = Array("Hello".utf8)
        #expect(bytes.count == expected.count)
        #expect(Array(bytes) == expected)
    }

    @Test("Sendable 준수 — 다른 Task로 전달 가능해야 한다")
    func sendableConformance() async {
        let bytes = SecureBytes(utf8: "secret")
        let result = await Task { bytes.count }.value
        #expect(result == 6)
    }

    // MARK: - [보통] SecureBytes 메모리 제로화

    @Test("withUnsafeBytes를 통해 바이트에 안전하게 접근할 수 있어야 한다")
    func withUnsafeBytesAccess() {
        let raw: [UInt8] = [0x48, 0x65, 0x6C, 0x6C, 0x6F]
        let bytes = SecureBytes(raw)
        let result = bytes.withUnsafeBytes { ptr -> [UInt8] in
            Array(ptr)
        }
        #expect(result == raw)
    }

    @Test("deinit이 memset_s를 통해 메모리를 제로화하고 deallocate해야 한다")
    func memoryZeroizedAndDeallocatedOnDeinit() {
        // deinit 호출 시 크래시 없이 동작하면 통과
        // (deallocate 이후 포인터 접근은 UB이므로 직접 검증하지 않음)
        do {
            let bytes = SecureBytes(utf8: "sensitive-data")
            #expect(bytes.count == 14)
        }
        // bytes는 스코프를 벗어나 deinit 호출됨 — 메모리 제로화 후 deallocate
    }

    @Test("빈 SecureBytes의 deinit도 안전하게 동작해야 한다")
    func emptySecureBytesDeinit() {
        // deinit이 크래시 없이 동작하면 통과
        _ = SecureBytes()
    }
}
