import Foundation
import SwiftData

@Model
public final class SFTPBookmark {
    public var id: UUID
    public var sessionId: UUID
    public var path: String
    public var name: String
    public var createdAt: Date

    public init(
        id: UUID,
        sessionId: UUID,
        path: String,
        name: String,
        createdAt: Date
    ) {
        self.id = id
        self.sessionId = sessionId
        self.path = path
        self.name = name
        self.createdAt = createdAt
    }
}
