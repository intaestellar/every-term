import Testing
import Foundation
@testable import EveryTerm

@Suite("Macro Model Tests")
struct MacroModelTests {

    // MARK: - [쉬움] 기본 생성 및 Codable

    @Test("Macro 기본값으로 생성 후 프로퍼티 일치 확인")
    @MainActor func createWithDefaults() {
        let macro = Macro(name: "Test Macro")

        #expect(macro.name == "Test Macro")
        #expect(macro.id != UUID())
    }

    @Test("MacroAction.type(text:) Codable 라운드트립")
    func typeActionCodable() throws {
        let action = MacroAction.type(text: "hello world")
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(action)
        let decoded = try decoder.decode(MacroAction.self, from: data)

        if case .type(let text) = decoded {
            #expect(text == "hello world")
        } else {
            #expect(Bool(false), ".type 액션이어야 한다")
        }
    }

    @Test("MacroAction.keyPress Codable 라운드트립")
    func keyPressActionCodable() throws {
        let action = MacroAction.keyPress(key: "Return", modifiers: ["command", "shift"])
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(action)
        let decoded = try decoder.decode(MacroAction.self, from: data)

        if case .keyPress(let key, let modifiers) = decoded {
            #expect(key == "Return")
            #expect(modifiers == ["command", "shift"])
        } else {
            #expect(Bool(false), ".keyPress 액션이어야 한다")
        }
    }

    @Test("MacroAction.wait(seconds:) Codable 라운드트립")
    func waitActionCodable() throws {
        let action = MacroAction.wait(seconds: 2.5)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(action)
        let decoded = try decoder.decode(MacroAction.self, from: data)

        if case .wait(let seconds) = decoded {
            #expect(seconds == 2.5)
        } else {
            #expect(Bool(false), ".wait 액션이어야 한다")
        }
    }

    @Test("MacroAction.waitForOutput Codable 라운드트립")
    func waitForOutputActionCodable() throws {
        let action = MacroAction.waitForOutput(pattern: "\\$\\s*$", timeout: 10.0)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(action)
        let decoded = try decoder.decode(MacroAction.self, from: data)

        if case .waitForOutput(let pattern, let timeout) = decoded {
            #expect(pattern == "\\$\\s*$")
            #expect(timeout == 10.0)
        } else {
            #expect(Bool(false), ".waitForOutput 액션이어야 한다")
        }
    }

    // MARK: - [보통] 배열 직렬화 / 프로퍼티

    @Test("[MacroAction] 배열 JSON 직렬화 라운드트립")
    func actionArraySerializationRoundTrip() throws {
        let actions: [MacroAction] = [
            .type(text: "ls -la"),
            .keyPress(key: "Return", modifiers: []),
            .wait(seconds: 1.0),
            .waitForOutput(pattern: "\\$", timeout: 5.0),
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(actions)
        let decoded = try decoder.decode([MacroAction].self, from: data)

        #expect(decoded.count == 4)
    }

    @Test("actionsData에 빈 배열 저장/복원")
    func emptyActionsDataRoundTrip() throws {
        let actions: [MacroAction] = []
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(actions)
        let decoded = try decoder.decode([MacroAction].self, from: data)

        #expect(decoded.isEmpty)
    }

    @Test("shortcutKey / shortcutModifiers nil 기본값 확인")
    @MainActor func shortcutDefaultsNil() {
        let macro = Macro(name: "No Shortcut")

        #expect(macro.shortcutKey == nil)
        #expect(macro.shortcutModifiers == nil)
    }
}
