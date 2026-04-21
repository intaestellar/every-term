import Foundation

/// Parses iTerm2 `.itermcolors` XML plist files into a ``TerminalTheme``.
public struct ITermColorsImporter: Sendable {
    public enum ImporterError: Error, Equatable {
        case malformedPlist
        case missingRequiredKey(String)
    }

    public init() {}

    public func importTheme(from data: Data, name: String) throws -> TerminalTheme {
        guard data.isEmpty == false else {
            throw ImporterError.malformedPlist
        }
        let raw: Any
        do {
            raw = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        } catch {
            throw ImporterError.malformedPlist
        }
        guard let dict = raw as? [String: Any] else {
            throw ImporterError.malformedPlist
        }

        let background = try color(from: dict["Background Color"], key: "Background Color")
        let foreground = try color(from: dict["Foreground Color"], key: "Foreground Color")
        let cursor = try color(from: dict["Cursor Color"], key: "Cursor Color")

        var palette: [ThemeColor] = []
        palette.reserveCapacity(16)
        for i in 0..<16 {
            let key = "Ansi \(i) Color"
            if let value = dict[key] {
                if let c = try? color(from: value, key: key) {
                    palette.append(c)
                }
            }
        }

        return TerminalTheme(
            name: name,
            foreground: foreground,
            background: background,
            cursor: cursor,
            ansiPalette: palette
        )
    }

    private func color(from raw: Any?, key: String) throws -> ThemeColor {
        guard let dict = raw as? [String: Any] else {
            throw ImporterError.missingRequiredKey(key)
        }
        let red = Self.component(dict["Red Component"])
        let green = Self.component(dict["Green Component"])
        let blue = Self.component(dict["Blue Component"])
        let alpha: Double
        if let alphaRaw = dict["Alpha Component"] {
            alpha = Self.component(alphaRaw)
        } else {
            alpha = 1.0
        }
        return ThemeColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    private static func component(_ raw: Any?) -> Double {
        let value: Double
        if let d = raw as? Double {
            value = d
        } else if let n = raw as? NSNumber {
            value = n.doubleValue
        } else {
            value = 0
        }
        return max(0.0, min(1.0, value))
    }
}
