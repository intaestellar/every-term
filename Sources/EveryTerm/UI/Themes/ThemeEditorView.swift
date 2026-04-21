import SwiftUI

/// Minimal theme editor surface. Lets the user pick a built-in theme as a
/// starting point, tweak foreground/background/cursor colors, and register
/// the result as a custom theme via ``AppThemeManager``.
@MainActor
public struct ThemeEditorView: View {
    @ObservedObject private var manager: AppThemeManager
    @State private var name: String
    @State private var foreground: Color
    @State private var background: Color
    @State private var cursor: Color

    public init(manager: AppThemeManager = .shared) {
        self.manager = manager
        let seed = manager.activeTheme
        self._name = State(initialValue: "\(seed.name) (Custom)")
        self._foreground = State(initialValue: Self.colorFromHex(seed.foreground) ?? .white)
        self._background = State(initialValue: Self.colorFromHex(seed.background) ?? .black)
        self._cursor = State(initialValue: Self.colorFromHex(seed.cursor) ?? .white)
    }

    public var body: some View {
        Form {
            Section("프리셋") {
                Picker("기본 테마", selection: Binding(
                    get: { manager.activeTheme.name },
                    set: { newValue in manager.activate(named: newValue) }
                )) {
                    ForEach(manager.availableThemes, id: \.name) { theme in
                        Text(theme.name).tag(theme.name)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("기본 색상") {
                TextField("테마 이름", text: $name)
                ColorPicker("전경색", selection: $foreground, supportsOpacity: false)
                ColorPicker("배경색", selection: $background, supportsOpacity: false)
                ColorPicker("커서", selection: $cursor, supportsOpacity: false)
            }

            Section {
                HStack {
                    Button("저장") { save() }
                        .keyboardShortcut(.defaultAction)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button("삭제", role: .destructive) {
                        manager.removeCustom(named: name)
                    }
                    .disabled(!manager.customThemes.contains { $0.name == name })
                }
            }
        }
        .padding(20)
        .frame(minWidth: 420, minHeight: 320)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("테마 편집기")
    }

    private func save() {
        let theme = TerminalTheme(
            name: name,
            foreground: ThemeColor(color: foreground),
            background: ThemeColor(color: background),
            cursor: ThemeColor(color: cursor),
            ansiPalette: manager.activeTheme.ansiPalette,
            isLight: manager.activeTheme.isLight
        )
        manager.registerCustom(theme)
        manager.activate(theme)
    }

    private static func colorFromHex(_ themeColor: ThemeColor?) -> Color? {
        guard let c = themeColor else { return nil }
        return Color(red: c.red, green: c.green, blue: c.blue, opacity: c.alpha)
    }
}

private extension ThemeColor {
    /// Convenience initializer so the editor can hand `Color` back to the
    /// theme model without string-hex round trips.
    init(color: Color) {
        #if canImport(AppKit)
        let ns = NSColor(color)
        let rgb = ns.usingColorSpace(.sRGB) ?? ns
        self.init(
            red: Double(rgb.redComponent),
            green: Double(rgb.greenComponent),
            blue: Double(rgb.blueComponent),
            alpha: Double(rgb.alphaComponent)
        )
        #else
        // Fallback path used by non-AppKit platforms (e.g. Linux CI).
        self.init(red: 0, green: 0, blue: 0, alpha: 1)
        #endif
    }
}
