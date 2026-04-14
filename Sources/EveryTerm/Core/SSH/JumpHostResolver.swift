import Foundation

public enum JumpHostResolverError: Error {
    case circularReference(sessionId: UUID)
    case missingJumpHost(jumpHostId: UUID)
}

@MainActor
public struct JumpHostResolver: Sendable {
    public init() {}

    public func resolveChain(for session: Session, allSessions: [Session]) throws -> [Session] {
        var chain: [Session] = []
        var visited = Set<UUID>()
        var current: Session? = session

        // Walk backwards through jump hosts
        while let s = current {
            if visited.contains(s.id) {
                throw JumpHostResolverError.circularReference(sessionId: s.id)
            }
            visited.insert(s.id)
            chain.insert(s, at: 0)

            if let jumpId = s.jumpHostId {
                guard let jumpHost = allSessions.first(where: { $0.id == jumpId }) else {
                    throw JumpHostResolverError.missingJumpHost(jumpHostId: jumpId)
                }
                current = jumpHost
            } else {
                current = nil
            }
        }

        return chain
    }
}
