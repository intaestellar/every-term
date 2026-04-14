import Testing
@testable import EveryTerm

@Suite("SessionType / AuthMethod 열거형 Tests")
struct SessionEnumTests {

    @Test("SessionType 모든 케이스 순회 확인")
    func sessionTypeAllCases() {
        let allCases = SessionType.allCases
        #expect(allCases.contains(.ssh))
        #expect(allCases.contains(.local))
        #expect(allCases.contains(.rdp))
        #expect(allCases.contains(.vnc))
        #expect(allCases.contains(.telnet))
        #expect(allCases.contains(.serial))
        #expect(allCases.count == 6)
    }

    @Test("AuthMethod 모든 케이스 순회 확인")
    func authMethodAllCases() {
        let allCases = AuthMethod.allCases
        #expect(allCases.contains(.password))
        #expect(allCases.contains(.key))
        #expect(allCases.contains(.agent))
        #expect(allCases.contains(.interactive))
        #expect(allCases.count == 4)
    }
}
