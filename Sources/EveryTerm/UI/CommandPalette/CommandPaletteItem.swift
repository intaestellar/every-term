import Foundation

/// Represents a single entry in the command palette (Cmd+Shift+P).
public struct CommandPaletteItem: Identifiable, Sendable, Equatable {
    public enum Kind: String, Sendable, Equatable {
        case session
        /// App-level commands (e.g. "Open Preferences", "Create Tunnel").
        ///
        /// - Important: **Plan Step 1-3 미완** — 이 케이스를 생성하는
        ///   팩토리 메서드(`.openPreferences`, `.createTunnel` 등)가 아직
        ///   없습니다. 커맨드 팔레트가 앱 액션과 통합될 때 추가 필요.
        case appCommand
    }

    public let id: UUID
    public let title: String
    public let subtitle: String?
    public let kind: Kind
    public let iconName: String

    public init(
        id: UUID = UUID(),
        title: String,
        subtitle: String? = nil,
        kind: Kind,
        iconName: String = "command"
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.kind = kind
        self.iconName = iconName
    }

    public static func == (lhs: CommandPaletteItem, rhs: CommandPaletteItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Session-backed convenience initializer

extension CommandPaletteItem {
    @MainActor
    public init(session: Session) {
        self.id = session.id
        self.title = session.name
        self.subtitle = session.host
        self.kind = .session
        self.iconName = Self.sfSymbolName(for: session.type)
    }

    private static func sfSymbolName(for type: SessionType) -> String {
        switch type {
        case .ssh, .telnet, .local:
            return "terminal"
        case .rdp:
            return "desktopcomputer"
        case .vnc:
            return "display"
        case .serial:
            return "cable.connector"
        }
    }
}
