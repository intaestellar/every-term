import Foundation
import SwiftData

public enum MacroAction: Codable, Sendable, Equatable {
    case type(text: String)
    case keyPress(key: String, modifiers: [String])
    case wait(seconds: Double)
    case waitForOutput(pattern: String, timeout: Double)
}

@Model
public final class Macro: @unchecked Sendable {
    public var id: UUID
    public var name: String
    public var macroDescription: String?
    public var actionsData: Data
    public var shortcutKey: String?
    public var shortcutModifiers: Int?
    public var createdAt: Date

    public init(name: String, macroDescription: String? = nil) {
        self.id = UUID()
        self.name = name
        self.macroDescription = macroDescription
        self.actionsData = Data()
        self.shortcutKey = nil
        self.shortcutModifiers = nil
        self.createdAt = Date()
    }
}
