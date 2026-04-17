import Foundation

@MainActor
public final class MenuBarViewModel {
    public static let maxQuickConnectItems = 5

    public var isMenuBarEnabled: Bool = true
    public private(set) var connectedSessionCount: Int = 0
    public private(set) var quickConnectItems: [Session] = []

    private let onSelectSession: ((UUID) -> Void)?

    public init(onSelectSession: ((UUID) -> Void)? = nil) {
        self.onSelectSession = onSelectSession
    }

    public func updateConnectedCount(_ count: Int) {
        connectedSessionCount = max(0, count)
    }

    public var badgeText: String? {
        if connectedSessionCount <= 0 { return nil }
        if connectedSessionCount <= 9 { return "\(connectedSessionCount)" }
        return "9+"
    }

    public func setSessions(_ sessions: [Session]) {
        let sorted = sessions.sorted { lhs, rhs in
            switch (lhs.lastConnectedAt, rhs.lastConnectedAt) {
            case let (l?, r?): return l > r
            case (_?, nil): return true
            case (nil, _?): return false
            case (nil, nil): return false
            }
        }
        quickConnectItems = Array(sorted.prefix(Self.maxQuickConnectItems))
    }

    public func activateQuickConnect(at index: Int) {
        guard quickConnectItems.indices.contains(index) else { return }
        onSelectSession?(quickConnectItems[index].id)
    }
}
