import Foundation

public enum SplitLayout: Sendable {
    case single
    case horizontal
    case vertical
}

public struct TabItem: Identifiable, Sendable {
    public let id: UUID
    public var title: String
    public var splitLayout: SplitLayout
    public var sessionId: UUID?
    public var connectionId: UUID?

    public init(
        id: UUID = UUID(),
        title: String,
        splitLayout: SplitLayout = .single,
        sessionId: UUID? = nil,
        connectionId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.splitLayout = splitLayout
        self.sessionId = sessionId
        self.connectionId = connectionId
    }
}
