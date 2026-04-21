import Foundation

/// Pure-value representation of a Spotlight searchable item. Kept separate
/// from `CSSearchableItemAttributeSet` so the builder can be unit-tested on
/// any platform without pulling in CoreSpotlight.
public struct SpotlightAttributes: Sendable, Equatable {
    public static let domainIdentifier = "com.everyterm.session"

    public let title: String
    public let contentDescription: String
    public let keywords: [String]
    public let uniqueIdentifier: String

    public init(
        title: String,
        contentDescription: String,
        keywords: [String],
        uniqueIdentifier: String
    ) {
        self.title = title
        self.contentDescription = contentDescription
        self.keywords = keywords
        self.uniqueIdentifier = uniqueIdentifier
    }

    @MainActor
    public init(session: Session, groupName: String? = nil) {
        var keywords: [String] = [session.type.rawValue]
        if let groupName, !groupName.isEmpty {
            keywords.append(groupName)
        }
        self.title = session.name
        self.contentDescription = "\(session.type.rawValue.uppercased()) \u{00B7} \(session.host)"
        self.keywords = keywords
        self.uniqueIdentifier = session.id.uuidString
    }

    @MainActor
    public static func buildBatch(_ sessions: [Session]) -> [SpotlightAttributes] {
        sessions.map { SpotlightAttributes(session: $0) }
    }
}
