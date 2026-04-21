import Foundation

public struct WelcomeCTAButton: Sendable, Equatable {
    public let title: String
    public let systemImage: String

    public init(title: String, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }
}

@MainActor
public final class WelcomeViewModel {
    public static let maxRecentSessions = 10

    public private(set) var recentSessions: [Session]
    public let ctaButtons: [WelcomeCTAButton]

    public init(sessions: [Session]) {
        self.ctaButtons = [
            WelcomeCTAButton(title: "새 세션 만들기", systemImage: "plus.circle"),
            WelcomeCTAButton(title: "SSH Config 임포트", systemImage: "square.and.arrow.down")
        ]
        self.recentSessions = Self.buildRecent(from: sessions)
    }

    public var shouldShowEmptyState: Bool {
        recentSessions.isEmpty
    }

    private static func buildRecent(from sessions: [Session]) -> [Session] {
        let sorted = sessions.sorted { lhs, rhs in
            switch (lhs.lastConnectedAt, rhs.lastConnectedAt) {
            case let (l?, r?):
                return l > r
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return false
            }
        }
        return Array(sorted.prefix(maxRecentSessions))
    }
}
