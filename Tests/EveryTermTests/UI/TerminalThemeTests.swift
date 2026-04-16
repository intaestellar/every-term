import Testing
@testable import EveryTerm

@Suite("TerminalTheme Tests")
struct TerminalThemeTests {

    @Test("내장 5개 테마 로드 확인")
    func builtInThemesExist() {
        let themes = TerminalTheme.builtInThemes
        #expect(themes.count == 5)

        let names = themes.map(\.name)
        #expect(names.contains("Dracula"))
        #expect(names.contains("Solarized Dark"))
        #expect(names.contains("Nord"))
        #expect(names.contains("One Dark"))
        #expect(names.contains("Default"))
    }

    @Test("각 테마의 필수 색상 필드가 nil이 아님")
    func requiredColorFieldsNotNil() {
        for theme in TerminalTheme.builtInThemes {
            #expect(theme.foreground != nil, "\(theme.name) foreground가 nil")
            #expect(theme.background != nil, "\(theme.name) background가 nil")
            #expect(theme.cursor != nil, "\(theme.name) cursor가 nil")
        }
    }

    @Test("커서 스타일 3종 생성 확인")
    func cursorStyles() {
        let block = CursorStyle.block
        let underline = CursorStyle.underline
        let bar = CursorStyle.bar

        #expect(block != underline)
        #expect(underline != bar)
        #expect(block != bar)
    }
}
