import Testing
import Foundation
@testable import EveryTerm

@Suite("SpotlightAttributes Tests")
@MainActor
struct SpotlightAttributesBuilderTests {

    // MARK: - [쉬움] 단일 세션 빌드

    @Test("단일 세션 → SpotlightAttributes.title == session.name")
    func titleMatchesSessionName() {
        let s = Session(name: "Production DB", type: .ssh, host: "db.prod", username: "u", authMethod: .password)
        let attrs = SpotlightAttributes(session: s)
        #expect(attrs.title == "Production DB")
    }

    @Test("contentDescription 에 host + 프로토콜 문자열 포함")
    func descriptionContainsHostAndProtocol() {
        let s = Session(name: "srv", type: .ssh, host: "example.com", username: "u", authMethod: .password)
        let attrs = SpotlightAttributes(session: s)
        #expect(attrs.contentDescription.contains("example.com"))
        #expect(attrs.contentDescription.lowercased().contains("ssh"))
    }

    @Test("keywords 배열에 그룹명 포함 (그룹 있을 때)")
    func keywordsIncludeGroupName() {
        let s = Session(name: "srv", type: .ssh, host: "h", username: "u", authMethod: .password)
        let attrs = SpotlightAttributes(session: s, groupName: "Servers")
        #expect(attrs.keywords.contains("Servers"))
    }

    // MARK: - [보통] 경계

    @Test("세션 이름에 특수문자 포함해도 crash 없이 문자열 반환")
    func specialCharactersSurvive() {
        let s = Session(name: "프로덕션 #1 <서버>", type: .ssh, host: "h", username: "u", authMethod: .password)
        let attrs = SpotlightAttributes(session: s)
        #expect(attrs.title.isEmpty == false)
    }

    @Test("그룹 없는 세션 → keywords 에 프로토콜 문자열만 포함 (빈 배열 아님)")
    func noGroupKeywordsContainProtocol() {
        let s = Session(name: "srv", type: .rdp, host: "h", username: "u", authMethod: .password)
        let attrs = SpotlightAttributes(session: s)
        #expect(attrs.keywords.isEmpty == false)
        #expect(attrs.keywords.map { $0.lowercased() }.contains("rdp"))
    }

    @Test("domainIdentifier == 'com.everyterm.session' 고정")
    func domainIdentifierFixed() {
        #expect(SpotlightAttributes.domainIdentifier == "com.everyterm.session")
    }

    @Test("세션 배열 → buildBatch 결과 카운트 == 입력 카운트")
    func buildBatchCount() {
        let sessions = (0..<5).map { i in
            Session(name: "s\(i)", type: .ssh, host: "h", username: "u", authMethod: .password)
        }
        let batch = SpotlightAttributes.buildBatch(sessions)
        #expect(batch.count == sessions.count)
    }
}
