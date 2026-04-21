import Foundation

/// Abstraction over the persistent store backing the "ignore unsafe protocol"
/// toggle. Production uses `@AppStorage`; tests can inject an in-memory
/// implementation.
@MainActor
public protocol UnsafeWarningStorage: AnyObject {
    func isIgnored(for sessionId: UUID) -> Bool
    func setIgnored(_ value: Bool, for sessionId: UUID)
}

public enum AcknowledgeAction: Sendable, Equatable {
    case proceed
    case cancel
}

public struct UnsafeWarningButton: Sendable, Equatable {
    public let title: String
    public let action: AcknowledgeAction

    public init(title: String, action: AcknowledgeAction) {
        self.title = title
        self.action = action
    }
}
