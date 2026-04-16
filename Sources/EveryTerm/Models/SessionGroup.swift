import Foundation

@MainActor
public final class SessionGroup: Identifiable {
    public let id: UUID
    public var name: String
    public var parentId: UUID?
    public var isExpanded: Bool
    public var icon: String?
    public var sortOrder: Int

    public init(
        id: UUID = UUID(),
        name: String,
        parentId: UUID? = nil,
        isExpanded: Bool = true,
        icon: String? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.parentId = parentId
        self.isExpanded = isExpanded
        self.icon = icon
        self.sortOrder = sortOrder
    }
}
