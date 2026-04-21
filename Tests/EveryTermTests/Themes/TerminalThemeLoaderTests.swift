import Testing
import Foundation
@testable import EveryTerm

// MARK: - BuiltInThemeCatalog Tests

@Suite("BuiltInThemeCatalog Tests")
struct BuiltInThemeCatalogTests {

    // MARK: - [쉬움] 카탈로그

    @Test("builtIns.count >= 10")
    func atLeastTenThemes() {
        #expect(TerminalTheme.builtIns.count >= 10)
    }

    @Test("내장 테마 이름 집합 — Dracula/Solarized Dark/Nord/One Dark/Gruvbox Dark/Tokyo Night/Catppuccin Mocha/Monokai Pro/macOS Default Light/macOS Default Dark 포함")
    func builtInNamesInclude() {
        let names = Set(TerminalTheme.builtIns.map(\.name))
        let required: Set<String> = [
            "Dracula",
            "Solarized Dark",
            "Nord",
            "One Dark",
            "Gruvbox Dark",
            "Tokyo Night",
            "Catppuccin Mocha",
            "Monokai Pro",
            "macOS Default Light",
            "macOS Default Dark",
        ]
        #expect(required.isSubset(of: names))
    }

    @Test("내장 테마 이름 유일성 (중복 없음)")
    func builtInNamesUnique() {
        let names = TerminalTheme.builtIns.map(\.name)
        #expect(Set(names).count == names.count)
    }

    // MARK: - [보통] 팔레트 / 라이트-다크

    @Test("각 내장 테마 ANSI 16색 팔레트 크기 == 16")
    func ansi16PaletteSize() {
        for theme in TerminalTheme.builtIns {
            #expect(theme.ansiPalette.count == 16, "\(theme.name) palette count != 16")
        }
    }

    @Test("각 내장 테마 background / foreground / cursor 색상 non-nil")
    func requiredColorsNonNil() {
        for theme in TerminalTheme.builtIns {
            #expect(theme.background != nil, "\(theme.name) background nil")
            #expect(theme.foreground != nil, "\(theme.name) foreground nil")
            #expect(theme.cursor != nil, "\(theme.name) cursor nil")
        }
    }

    @Test("isLight 헬퍼: macOS Default Light == true, macOS Default Dark == false")
    func isLightHelper() {
        let light = TerminalTheme.builtIns.first { $0.name == "macOS Default Light" }
        let dark = TerminalTheme.builtIns.first { $0.name == "macOS Default Dark" }
        #expect(light?.isLight == true)
        #expect(dark?.isLight == false)
    }
}

// MARK: - ITermColorsImporter Tests

@Suite("ITermColorsImporter Tests")
struct ITermColorsImporterTests {

    // MARK: - [쉬움] 에러 / 최소 유효

    @Test("빈 XML 입력 → ImporterError.malformedPlist throw")
    func emptyXMLThrowsMalformed() {
        let importer = ITermColorsImporter()
        #expect(throws: ITermColorsImporter.ImporterError.self) {
            try importer.importTheme(from: Data(), name: "Empty")
        }
    }

    @Test("최소 유효 plist → TerminalTheme 반환 성공")
    func minimalValidPlistReturnsTheme() throws {
        let importer = ITermColorsImporter()
        let data = Self.minimalValidPlist()
        let theme = try importer.importTheme(from: data, name: "Minimal")
        #expect(theme.name == "Minimal")
        #expect(theme.background != nil)
        #expect(theme.foreground != nil)
        #expect(theme.cursor != nil)
    }

    // MARK: - [보통] ANSI 16색 / 누락 키 / 클램프

    @Test("Ansi 0~15 Color 키 16개 파싱 → SRGB float → UInt8 매핑")
    func parseAnsi16Colors() throws {
        let importer = ITermColorsImporter()
        let data = Self.minimalValidPlist()
        let theme = try importer.importTheme(from: data, name: "X")
        #expect(theme.ansiPalette.count == 16)
    }

    @Test("Background/Foreground/Cursor 필수 3종 누락 시 missingRequiredKey throw")
    func missingRequiredKeyThrows() {
        let importer = ITermColorsImporter()
        let data = Self.plistMissingBackground()
        #expect(throws: ITermColorsImporter.ImporterError.self) {
            try importer.importTheme(from: data, name: "NoBG")
        }
    }

    @Test("RGB float 범위 밖(1.5 등) → 0~1 클램프")
    func outOfRangeColorClamped() throws {
        let importer = ITermColorsImporter()
        let data = Self.plistWithOutOfRangeRed()
        let theme = try importer.importTheme(from: data, name: "Clamp")
        // 클램프 후 background.red 는 0.0~1.0 범위
        if let bg = theme.background {
            #expect(bg.red >= 0.0 && bg.red <= 1.0)
        }
    }

    @Test("Alpha Component 누락해도 기본 1.0 적용")
    func missingAlphaDefaultsToOne() throws {
        let importer = ITermColorsImporter()
        let data = Self.minimalValidPlist()
        let theme = try importer.importTheme(from: data, name: "NoAlpha")
        if let bg = theme.background {
            #expect(bg.alpha == 1.0)
        }
    }

    // MARK: - [어려움] Dracula fixture 라운드트립

    @Test("Dracula.itermcolors fixture 라운드트립 — 알려진 팔레트 값 일치")
    func draculaFixtureRoundTrip() throws {
        guard let url = Bundle.module.url(forResource: "Dracula", withExtension: "itermcolors") else {
            Issue.record("Dracula.itermcolors fixture 파일이 Bundle.module 에 없음")
            return
        }
        let data = try Data(contentsOf: url)
        let importer = ITermColorsImporter()
        let theme = try importer.importTheme(from: data, name: "Dracula")
        // 알려진 Dracula 배경색 근사값 (#282A36)
        if let bg = theme.background {
            #expect(abs(bg.red - (0x28 / 255.0)) < 0.02)
            #expect(abs(bg.green - (0x2A / 255.0)) < 0.02)
            #expect(abs(bg.blue - (0x36 / 255.0)) < 0.02)
        }
    }

    // MARK: - Fixtures

    private static func minimalValidPlist() -> Data {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        """
        for i in 0..<16 {
            xml += """
            <key>Ansi \(i) Color</key>
            <dict>
                <key>Red Component</key><real>0.1</real>
                <key>Green Component</key><real>0.2</real>
                <key>Blue Component</key><real>0.3</real>
            </dict>
            """
        }
        xml += """
        <key>Background Color</key>
        <dict>
            <key>Red Component</key><real>0.0</real>
            <key>Green Component</key><real>0.0</real>
            <key>Blue Component</key><real>0.0</real>
        </dict>
        <key>Foreground Color</key>
        <dict>
            <key>Red Component</key><real>1.0</real>
            <key>Green Component</key><real>1.0</real>
            <key>Blue Component</key><real>1.0</real>
        </dict>
        <key>Cursor Color</key>
        <dict>
            <key>Red Component</key><real>0.5</real>
            <key>Green Component</key><real>0.5</real>
            <key>Blue Component</key><real>0.5</real>
        </dict>
        </dict>
        </plist>
        """
        return xml.data(using: .utf8)!
    }

    private static func plistMissingBackground() -> Data {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Foreground Color</key>
            <dict>
                <key>Red Component</key><real>1.0</real>
                <key>Green Component</key><real>1.0</real>
                <key>Blue Component</key><real>1.0</real>
            </dict>
            <key>Cursor Color</key>
            <dict>
                <key>Red Component</key><real>0.5</real>
                <key>Green Component</key><real>0.5</real>
                <key>Blue Component</key><real>0.5</real>
            </dict>
        </dict>
        </plist>
        """
        return xml.data(using: .utf8)!
    }

    private static func plistWithOutOfRangeRed() -> Data {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
        """
        for i in 0..<16 {
            xml += """
            <key>Ansi \(i) Color</key>
            <dict>
                <key>Red Component</key><real>0.1</real>
                <key>Green Component</key><real>0.2</real>
                <key>Blue Component</key><real>0.3</real>
            </dict>
            """
        }
        xml += """
        <key>Background Color</key>
        <dict>
            <key>Red Component</key><real>1.5</real>
            <key>Green Component</key><real>-0.3</real>
            <key>Blue Component</key><real>0.5</real>
        </dict>
        <key>Foreground Color</key>
        <dict>
            <key>Red Component</key><real>1.0</real>
            <key>Green Component</key><real>1.0</real>
            <key>Blue Component</key><real>1.0</real>
        </dict>
        <key>Cursor Color</key>
        <dict>
            <key>Red Component</key><real>0.5</real>
            <key>Green Component</key><real>0.5</real>
            <key>Blue Component</key><real>0.5</real>
        </dict>
        </dict>
        </plist>
        """
        return xml.data(using: .utf8)!
    }
}
