import Foundation
import Combine

/// Central hub for the currently active terminal theme. Vends the active
/// `TerminalTheme`, publishes changes to observers, and exposes custom theme
/// registration APIs for user-imported or edited palettes.
@MainActor
public final class AppThemeManager: ObservableObject {
    @Published public private(set) var activeTheme: TerminalTheme
    @Published public private(set) var customThemes: [TerminalTheme] = []

    public static let shared = AppThemeManager()

    public init(
        initialTheme: TerminalTheme = TerminalTheme.builtIns.first ?? .dracula,
        customThemes: [TerminalTheme] = []
    ) {
        self.activeTheme = initialTheme
        self.customThemes = customThemes
    }

    /// Built-ins + user-provided themes in display order.
    public var availableThemes: [TerminalTheme] {
        TerminalTheme.builtIns + customThemes
    }

    /// Activate the theme identified by `name`. Silently ignores unknown names.
    public func activate(named name: String) {
        guard let theme = availableThemes.first(where: { $0.name == name }) else { return }
        activeTheme = theme
    }

    /// Activate an arbitrary theme (used by the editor for live preview).
    public func activate(_ theme: TerminalTheme) {
        activeTheme = theme
    }

    /// Persist a custom theme. If a theme with the same name already exists
    /// it is replaced to keep the catalog unique by name.
    public func registerCustom(_ theme: TerminalTheme) {
        if let existing = customThemes.firstIndex(where: { $0.name == theme.name }) {
            customThemes[existing] = theme
        } else {
            customThemes.append(theme)
        }
    }

    /// Remove a previously registered custom theme by name.
    public func removeCustom(named name: String) {
        customThemes.removeAll { $0.name == name }
        if activeTheme.name == name,
           let fallback = TerminalTheme.builtIns.first {
            activeTheme = fallback
        }
    }
}
