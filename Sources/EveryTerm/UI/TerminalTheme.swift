import Foundation

public struct ThemeColor: Sendable, Equatable {
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

public struct TerminalTheme: Sendable, Equatable {
    public let name: String
    public let foreground: ThemeColor?
    public let background: ThemeColor?
    public let cursor: ThemeColor?
    public let ansiPalette: [ThemeColor]
    public let isLight: Bool

    public init(
        name: String,
        foreground: ThemeColor?,
        background: ThemeColor?,
        cursor: ThemeColor?,
        ansiPalette: [ThemeColor] = [],
        isLight: Bool = false
    ) {
        self.name = name
        self.foreground = foreground
        self.background = background
        self.cursor = cursor
        self.ansiPalette = ansiPalette
        self.isLight = isLight
    }

    /// 10개의 내장 테마 카탈로그 (Dracula / Solarized Dark / Nord / One Dark /
    /// Gruvbox Dark / Tokyo Night / Catppuccin Mocha / Monokai Pro /
    /// macOS Default Light / macOS Default Dark).
    public static let builtIns: [TerminalTheme] = [
        .dracula,
        .solarizedDark,
        .nord,
        .oneDark,
        .gruvboxDark,
        .tokyoNight,
        .catppuccinMocha,
        .monokaiPro,
        .macOSDefaultLight,
        .macOSDefaultDark
    ]

    /// Look up a built-in theme by name
    public static func theme(named name: String) -> TerminalTheme? {
        builtIns.first { $0.name == name }
    }
}

// MARK: - Built-in theme definitions

extension TerminalTheme {
    fileprivate static func palette(_ hexes: [String]) -> [ThemeColor] {
        precondition(hexes.count == 16, "ANSI palette must have 16 colours")
        return hexes.map { ThemeColor(hex: $0) }
    }

    public static let dracula = TerminalTheme(
        name: "Dracula",
        foreground: ThemeColor(hex: "F8F8F2"),
        background: ThemeColor(hex: "282A36"),
        cursor: ThemeColor(hex: "F8F8F2"),
        ansiPalette: palette([
            "000000", "FF5555", "50FA7B", "F1FA8C",
            "BD93F9", "FF79C6", "8BE9FD", "BFBFBF",
            "4D4D4D", "FF6E67", "5AF78E", "F4F99D",
            "CAA9FA", "FF92D0", "9AEDFE", "E6E6E6"
        ])
    )

    public static let solarizedDark = TerminalTheme(
        name: "Solarized Dark",
        foreground: ThemeColor(hex: "839496"),
        background: ThemeColor(hex: "002B36"),
        cursor: ThemeColor(hex: "839496"),
        ansiPalette: palette([
            "073642", "DC322F", "859900", "B58900",
            "268BD2", "D33682", "2AA198", "EEE8D5",
            "002B36", "CB4B16", "586E75", "657B83",
            "839496", "6C71C4", "93A1A1", "FDF6E3"
        ])
    )

    public static let nord = TerminalTheme(
        name: "Nord",
        foreground: ThemeColor(hex: "D8DEE9"),
        background: ThemeColor(hex: "2E3440"),
        cursor: ThemeColor(hex: "D8DEE9"),
        ansiPalette: palette([
            "3B4252", "BF616A", "A3BE8C", "EBCB8B",
            "81A1C1", "B48EAD", "88C0D0", "E5E9F0",
            "4C566A", "BF616A", "A3BE8C", "EBCB8B",
            "81A1C1", "B48EAD", "8FBCBB", "ECEFF4"
        ])
    )

    public static let oneDark = TerminalTheme(
        name: "One Dark",
        foreground: ThemeColor(hex: "ABB2BF"),
        background: ThemeColor(hex: "282C34"),
        cursor: ThemeColor(hex: "528BFF"),
        ansiPalette: palette([
            "282C34", "E06C75", "98C379", "E5C07B",
            "61AFEF", "C678DD", "56B6C2", "ABB2BF",
            "5C6370", "E06C75", "98C379", "E5C07B",
            "61AFEF", "C678DD", "56B6C2", "FFFFFF"
        ])
    )

    public static let gruvboxDark = TerminalTheme(
        name: "Gruvbox Dark",
        foreground: ThemeColor(hex: "EBDBB2"),
        background: ThemeColor(hex: "282828"),
        cursor: ThemeColor(hex: "EBDBB2"),
        ansiPalette: palette([
            "282828", "CC241D", "98971A", "D79921",
            "458588", "B16286", "689D6A", "A89984",
            "928374", "FB4934", "B8BB26", "FABD2F",
            "83A598", "D3869B", "8EC07C", "EBDBB2"
        ])
    )

    public static let tokyoNight = TerminalTheme(
        name: "Tokyo Night",
        foreground: ThemeColor(hex: "C0CAF5"),
        background: ThemeColor(hex: "1A1B26"),
        cursor: ThemeColor(hex: "C0CAF5"),
        ansiPalette: palette([
            "15161E", "F7768E", "9ECE6A", "E0AF68",
            "7AA2F7", "BB9AF7", "7DCFFF", "A9B1D6",
            "414868", "F7768E", "9ECE6A", "E0AF68",
            "7AA2F7", "BB9AF7", "7DCFFF", "C0CAF5"
        ])
    )

    public static let catppuccinMocha = TerminalTheme(
        name: "Catppuccin Mocha",
        foreground: ThemeColor(hex: "CDD6F4"),
        background: ThemeColor(hex: "1E1E2E"),
        cursor: ThemeColor(hex: "F5E0DC"),
        ansiPalette: palette([
            "45475A", "F38BA8", "A6E3A1", "F9E2AF",
            "89B4FA", "F5C2E7", "94E2D5", "BAC2DE",
            "585B70", "F38BA8", "A6E3A1", "F9E2AF",
            "89B4FA", "F5C2E7", "94E2D5", "A6ADC8"
        ])
    )

    public static let monokaiPro = TerminalTheme(
        name: "Monokai Pro",
        foreground: ThemeColor(hex: "FCFCFA"),
        background: ThemeColor(hex: "2D2A2E"),
        cursor: ThemeColor(hex: "FCFCFA"),
        ansiPalette: palette([
            "403E41", "FF6188", "A9DC76", "FFD866",
            "FC9867", "AB9DF2", "78DCE8", "FCFCFA",
            "727072", "FF6188", "A9DC76", "FFD866",
            "FC9867", "AB9DF2", "78DCE8", "FCFCFA"
        ])
    )

    public static let macOSDefaultLight = TerminalTheme(
        name: "macOS Default Light",
        foreground: ThemeColor(hex: "000000"),
        background: ThemeColor(hex: "FFFFFF"),
        cursor: ThemeColor(hex: "000000"),
        ansiPalette: palette([
            "000000", "990000", "00A600", "999900",
            "0000B2", "B200B2", "00A6B2", "BFBFBF",
            "666666", "E50000", "00D900", "E5E500",
            "0000FF", "E500E5", "00E5E5", "E5E5E5"
        ]),
        isLight: true
    )

    public static let macOSDefaultDark = TerminalTheme(
        name: "macOS Default Dark",
        foreground: ThemeColor(hex: "FFFFFF"),
        background: ThemeColor(hex: "1E1E1E"),
        cursor: ThemeColor(hex: "FFFFFF"),
        ansiPalette: palette([
            "000000", "C91B00", "00C200", "C7C400",
            "0225C7", "CA30C7", "00C5C7", "C7C7C7",
            "686868", "FF6E67", "5FFA68", "FFFC67",
            "6871FF", "FF77FF", "60FDFF", "FFFFFF"
        ]),
        isLight: false
    )
}

/// Terminal appearance settings stored via AppStorage keys
public enum TerminalAppearanceKeys {
    public static let themeName = "terminalTheme"
    public static let fontName = "terminalFontName"
    public static let fontSize = "terminalFontSize"
    public static let cursorStyle = "terminalCursorStyle"
    public static let backgroundOpacity = "terminalBackgroundOpacity"
}
