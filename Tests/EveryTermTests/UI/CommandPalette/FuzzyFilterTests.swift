import Testing
import Foundation
@testable import EveryTerm

// MARK: - CommandPaletteItem Tests

@Suite("CommandPaletteItem Tests")
@MainActor
struct CommandPaletteItemTests {

    // MARK: - [쉬움] enum / 필드

    @Test("CommandPaletteItem.Kind 케이스(session/appCommand) rawValue 라운드트립")
    func kindRawValueRoundTrip() {
        let s = CommandPaletteItem.Kind.session
        let a = CommandPaletteItem.Kind.appCommand
        #expect(CommandPaletteItem.Kind(rawValue: s.rawValue) == .session)
        #expect(CommandPaletteItem.Kind(rawValue: a.rawValue) == .appCommand)
    }

    @Test("초기화 후 id / title / subtitle / kind 필드 저장")
    func initializationStoresFields() {
        let id = UUID()
        let item = CommandPaletteItem(
            id: id,
            title: "Open Tunnel",
            subtitle: "SSH",
            kind: .appCommand
        )
        #expect(item.id == id)
        #expect(item.title == "Open Tunnel")
        #expect(item.subtitle == "SSH")
        #expect(item.kind == .appCommand)
    }

    @Test("동일 id 두 인스턴스 == 비교 true (Equatable)")
    func equatableById() {
        let id = UUID()
        let a = CommandPaletteItem(id: id, title: "X", subtitle: nil, kind: .session)
        let b = CommandPaletteItem(id: id, title: "Y", subtitle: nil, kind: .appCommand)
        #expect(a == b)
    }

    @Test("Sendable + Identifiable 준수 (컴파일)")
    func sendableIdentifiableConformance() {
        func requireSendable<T: Sendable>(_ t: T.Type) {}
        func requireIdentifiable<T: Identifiable>(_ t: T.Type) {}
        requireSendable(CommandPaletteItem.self)
        requireIdentifiable(CommandPaletteItem.self)
    }

    // MARK: - [보통] 세션 기반 아이콘 매핑

    @Test("Session 기반 생성자: SSH 세션 → 'terminal' SF Symbol 매핑")
    func iconMappingSSH() {
        let s = Session(name: "srv", type: .ssh, host: "h", username: "u", authMethod: .password)
        let item = CommandPaletteItem(session: s)
        #expect(item.iconName == "terminal")
    }

    @Test("Session 기반 생성자: RDP 세션 → 'desktopcomputer' SF Symbol 매핑")
    func iconMappingRDP() {
        let s = Session(name: "win", type: .rdp, host: "h", username: "u", authMethod: .password)
        let item = CommandPaletteItem(session: s)
        #expect(item.iconName == "desktopcomputer")
    }
}

// MARK: - CommandPaletteFuzzyFilter Tests

@Suite("CommandPaletteFuzzyFilter Tests")
@MainActor
struct CommandPaletteFuzzyFilterTests {

    private func makeItems(_ titles: [String]) -> [CommandPaletteItem] {
        titles.map { CommandPaletteItem(id: UUID(), title: $0, subtitle: nil, kind: .session) }
    }

    // MARK: - [쉬움] 기본

    @Test("빈 쿼리 → 입력 배열 전체 그대로 반환")
    func emptyQueryReturnsAll() {
        let filter = CommandPaletteFuzzyFilter()
        let items = makeItems(["ssh prod", "rdp dev", "vnc staging"])
        let result = filter.filter(items: items, query: "")
        #expect(result.count == items.count)
    }

    @Test("단일 문자 쿼리 's' → 'ssh prod' 매칭 true")
    func singleCharMatches() {
        let filter = CommandPaletteFuzzyFilter()
        let items = makeItems(["ssh prod", "rdp dev"])
        let result = filter.filter(items: items, query: "s")
        #expect(result.contains(where: { $0.title == "ssh prod" }))
    }

    @Test("대소문자 무시: 'SSH' 쿼리 → 'ssh prod' 매칭 true")
    func caseInsensitiveMatch() {
        let filter = CommandPaletteFuzzyFilter()
        let items = makeItems(["ssh prod"])
        let result = filter.filter(items: items, query: "SSH")
        #expect(result.count == 1)
    }

    // MARK: - [보통] 퍼지

    @Test("퍼지 매칭: 'spd' → 'ssh prod' 매칭 true (문자 순서 유지)")
    func fuzzyMatchOrdered() {
        let filter = CommandPaletteFuzzyFilter()
        let items = makeItems(["ssh prod"])
        let result = filter.filter(items: items, query: "spd")
        #expect(result.count == 1)
    }

    @Test("퍼지 매칭: 'dps' → 'ssh prod' 매칭 false (순서 불일치)")
    func fuzzyMatchWrongOrderFails() {
        let filter = CommandPaletteFuzzyFilter()
        let items = makeItems(["ssh prod"])
        let result = filter.filter(items: items, query: "dps")
        #expect(result.isEmpty)
    }

    @Test("점수 기반 정렬: prefix 매칭이 산발 매칭보다 상위")
    func prefixMatchOutranksScattered() {
        let filter = CommandPaletteFuzzyFilter()
        let items = makeItems(["access", "ssh prod"])
        let result = filter.filter(items: items, query: "ssh")
        #expect(result.first?.title == "ssh prod")
    }

    @Test("연속 매칭 구간이 불연속 매칭보다 상위 점수")
    func contiguousBeatsFragmented() {
        let filter = CommandPaletteFuzzyFilter()
        let items = makeItems(["c-m-d", "command"])
        let result = filter.filter(items: items, query: "cmd")
        #expect(result.first?.title == "command")
    }

    @Test("한글 쿼리 '서버' → '서버 프로덕션' 매칭 true")
    func unicodeKoreanMatch() {
        let filter = CommandPaletteFuzzyFilter()
        let items = makeItems(["서버 프로덕션", "staging"])
        let result = filter.filter(items: items, query: "서버")
        #expect(result.contains(where: { $0.title == "서버 프로덕션" }))
    }

    // MARK: - [어려움] 성능

    @Test("1000개 아이템 × 8자 쿼리 100ms 이내 필터링")
    func performanceUnder100ms() {
        let filter = CommandPaletteFuzzyFilter()
        let items = makeItems((0..<1000).map { "session_\($0)_host" })
        let start = Date()
        _ = filter.filter(items: items, query: "session1")
        let elapsed = Date().timeIntervalSince(start)
        #expect(elapsed < 0.1)
    }
}
