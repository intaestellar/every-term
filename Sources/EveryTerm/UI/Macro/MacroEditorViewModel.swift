import Foundation

@MainActor
public class MacroEditorViewModel: ObservableObject {
    @Published public var actions: [MacroAction] = []

    public init() {}

    public func addAction(_ action: MacroAction) {
        actions.append(action)
    }

    public func deleteAction(at index: Int) {
        guard index >= 0 && index < actions.count else { return }
        actions.remove(at: index)
    }

    public func moveAction(from source: Int, to destination: Int) {
        guard source >= 0 && source < actions.count else { return }
        let action = actions.remove(at: source)
        let insertIndex = destination > source ? destination - 1 : destination
        let clampedIndex = min(insertIndex, actions.count)
        actions.insert(action, at: clampedIndex)
    }

    public func exportJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(actions)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw MacroEditorError.exportFailed
        }
        return jsonString
    }

    public func importJSON(_ jsonString: String) throws {
        guard let data = jsonString.data(using: .utf8) else {
            throw MacroEditorError.importFailed
        }
        let decoder = JSONDecoder()
        let decoded = try decoder.decode([MacroAction].self, from: data)
        actions = decoded
    }
}

public enum MacroEditorError: Error {
    case exportFailed
    case importFailed
}
