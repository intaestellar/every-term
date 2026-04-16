import Testing
import Foundation
@testable import EveryTerm

@Suite("SessionStore JSON Export/Import Tests")
struct SessionStoreExportTests {

    @Test("세션 목록 JSON 내보내기 후 재가져오기 라운드트립")
    @MainActor func exportImportRoundTrip() throws {
        let store = SessionStore.forTesting()
        let session = Session(
            name: "Export Test",
            type: .ssh,
            host: "export.com",
            username: "user",
            authMethod: .key
        )

        try store.add(session)
        let jsonData = try store.exportToJSON()

        let importStore = SessionStore.forTesting()
        try importStore.importFromJSON(jsonData)

        let imported = importStore.allSessions
        #expect(imported.contains(where: { $0.name == "Export Test" && $0.host == "export.com" }))
    }

    @Test("빈 목록 내보내기/가져오기")
    @MainActor func emptyListExportImport() throws {
        let store = SessionStore.forTesting()
        let jsonData = try store.exportToJSON()

        let importStore = SessionStore.forTesting()
        try importStore.importFromJSON(jsonData)

        #expect(importStore.allSessions.isEmpty)
    }

    @Test("잘못된 JSON 가져오기 시 에러 처리")
    @MainActor func invalidJSONThrows() {
        let store = SessionStore.forTesting()
        let invalidData = Data("not valid json{{{".utf8)

        #expect(throws: Error.self) {
            try store.importFromJSON(invalidData)
        }
    }
}
