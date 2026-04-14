import Foundation

public struct ThemeColor: Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        self.red = Double((rgb >> 16) & 0xFF) / 255.0
        self.green = Double((rgb >> 8) & 0xFF) / 255.0
        self.blue = Double(rgb & 0xFF) / 255.0
        self.alpha = 1.0
    }
}

public enum CursorStyle: String, Sendable, Equatable, CaseIterable {
    case block
    case underline
    case bar
}

public struct TerminalTheme: Sendable {
    public let name: String
    public let foreground: ThemeColor?
    public let background: ThemeColor?
    public let cursor: ThemeColor?

    public init(name: String, foreground: ThemeColor?, background: ThemeColor?, cursor: ThemeColor?) {
        self.name = name
        self.foreground = foreground
        self.background = background
        self.cursor = cursor
    }

    public static let builtInThemes: [TerminalTheme] = [
        TerminalTheme(
            name: "Default",
            foreground: ThemeColor(hex: "FFFFFF"),
            background: ThemeColor(hex: "000000"),
            cursor: ThemeColor(hex: "FFFFFF")
        ),
        TerminalTheme(
            name: "Dracula",
            foreground: ThemeColor(hex: "F8F8F2"),
            background: ThemeColor(hex: "282A36"),
            cursor: ThemeColor(hex: "F8F8F2")
        ),
        TerminalTheme(
            name: "Solarized Dark",
            foreground: ThemeColor(hex: "839496"),
            background: ThemeColor(hex: "002B36"),
            cursor: ThemeColor(hex: "839496")
        ),
        TerminalTheme(
            name: "Nord",
            foreground: ThemeColor(hex: "D8DEE9"),
            background: ThemeColor(hex: "2E3440"),
            cursor: ThemeColor(hex: "D8DEE9")
        ),
        TerminalTheme(
            name: "One Dark",
            foreground: ThemeColor(hex: "ABB2BF"),
            background: ThemeColor(hex: "282C34"),
            cursor: ThemeColor(hex: "528BFF")
        ),
    ]

    /// Look up a built-in theme by name
    public static func theme(named name: String) -> TerminalTheme? {
        builtInThemes.first { $0.name == name }
    }
}

/// Terminal appearance settings stored via AppStorage keys
public enum TerminalAppearanceKeys {
    public static let themeName = "terminalTheme"
    public static let fontName = "terminalFontName"
    public static let fontSize = "terminalFontSize"
    public static let cursorStyle = "terminalCursorStyle"
    public static let backgroundOpacity = "terminalBackgroundOpacity"
}
