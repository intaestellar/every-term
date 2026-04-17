import Foundation
#if canImport(CoreServices) && canImport(CoreSpotlight)
import CoreSpotlight
import CoreServices
#endif

/// Converts ``SpotlightAttributes`` into `CSSearchableItem` and posts them to
/// the default searchable index. A skeleton implementation — the production
/// version will debounce writes and stream delta updates from `SessionStore`.
@MainActor
public final class SpotlightIndexer {
    public static let defaultDomainIdentifier = SpotlightAttributes.domainIdentifier

    public init() {}

    /// Rebuild the Spotlight index for the given sessions. A full rebuild is
    /// acceptable for EveryTerm's expected session count (<= a few hundred).
    public func reindex(sessions: [Session]) async throws {
        let attributes = SpotlightAttributes.buildBatch(sessions)
        try await index(attributes: attributes)
    }

    /// Remove all indexed items under EveryTerm's domain identifier.
    public func clear() async throws {
        #if canImport(CoreSpotlight)
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            CSSearchableIndex.default().deleteSearchableItems(
                withDomainIdentifiers: [Self.defaultDomainIdentifier]
            ) { error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
        #endif
    }

    /// Index the provided pure-value attributes.
    public func index(attributes: [SpotlightAttributes]) async throws {
        #if canImport(CoreSpotlight)
        let items = attributes.map { attr -> CSSearchableItem in
            let set = CSSearchableItemAttributeSet(itemContentType: "public.item")
            set.title = attr.title
            set.contentDescription = attr.contentDescription
            set.keywords = attr.keywords
            return CSSearchableItem(
                uniqueIdentifier: attr.uniqueIdentifier,
                domainIdentifier: SpotlightAttributes.domainIdentifier,
                attributeSet: set
            )
        }
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            CSSearchableIndex.default().indexSearchableItems(items) { error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
        #else
        _ = attributes
        #endif
    }
}
