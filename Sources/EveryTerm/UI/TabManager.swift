import Foundation
import Combine

@MainActor
public final class TabManager: ObservableObject {
    @Published public private(set) var tabs: [TabItem] = []
    @Published public var activeTabId: UUID?

    /// Active connections keyed by tab ID
    private var connections: [UUID: any RemoteConnection] = [:]

    public init() {}

    public func addTab(_ tab: TabItem) {
        tabs.append(tab)
        if activeTabId == nil {
            activeTabId = tab.id
        }
    }

    public func removeTab(_ id: UUID) {
        tabs.removeAll(where: { $0.id == id })
        connections.removeValue(forKey: id)
        if activeTabId == id {
            activeTabId = tabs.first?.id
        }
    }

    public func setActiveTab(_ id: UUID) {
        if tabs.contains(where: { $0.id == id }) {
            activeTabId = id
        }
    }

    public func moveTab(from source: Int, to destination: Int) {
        guard source >= 0, source < tabs.count, destination >= 0, destination <= tabs.count else { return }
        let tab = tabs.remove(at: source)
        let insertIndex = min(destination, tabs.count)
        tabs.insert(tab, at: insertIndex)
    }

    /// Set the connection for a tab
    public func setConnection(_ connection: any RemoteConnection, forTab tabId: UUID) {
        connections[tabId] = connection
    }

    /// Get the connection for a tab
    public func connection(forTab tabId: UUID) -> (any RemoteConnection)? {
        connections[tabId]
    }

    /// Check if a tab has an active connection
    public func hasActiveConnection(tabId: UUID) async -> Bool {
        guard let connection = connections[tabId] else { return false }
        let state = await connection.state
        switch state {
        case .connected, .connecting, .reconnecting:
            return true
        default:
            return false
        }
    }

    /// Select the tab at a given 1-based index (for Cmd+1..9 shortcuts)
    public func selectTab(at index: Int) {
        let zeroIndex = index - 1
        guard zeroIndex >= 0, zeroIndex < tabs.count else { return }
        activeTabId = tabs[zeroIndex].id
    }

    /// Select the next tab
    public func selectNextTab() {
        guard let currentId = activeTabId,
              let currentIndex = tabs.firstIndex(where: { $0.id == currentId }) else { return }
        let nextIndex = (currentIndex + 1) % tabs.count
        activeTabId = tabs[nextIndex].id
    }

    /// Select the previous tab
    public func selectPreviousTab() {
        guard let currentId = activeTabId,
              let currentIndex = tabs.firstIndex(where: { $0.id == currentId }) else { return }
        let prevIndex = (currentIndex - 1 + tabs.count) % tabs.count
        activeTabId = tabs[prevIndex].id
    }

    /// Close the active tab
    public func closeActiveTab() {
        guard let id = activeTabId else { return }
        removeTab(id)
    }

    // MARK: - Protocol routing

    /// Route kinds understood by the main window content pane.
    ///
    /// Keeping this as a pure enum (no SwiftUI dependency) lets the
    /// routing decision be unit-tested without instantiating views, and
    /// keeps `TabManager` free of `SwiftUI` imports.
    public enum ContentRoute: Sendable, Equatable {
        case terminal        // SSH / Local / Telnet / Serial share the terminal surface
        case rdp
        case vnc
    }

    /// Decide which view kind should be rendered for a given session
    /// type. RDP/VNC currently render placeholder surfaces; everything
    /// else goes through the shared terminal view.
    public static func contentRoute(for type: SessionType) -> ContentRoute {
        switch type {
        case .rdp:
            return .rdp
        case .vnc:
            return .vnc
        case .ssh, .local, .telnet, .serial:
            return .terminal
        }
    }
}
