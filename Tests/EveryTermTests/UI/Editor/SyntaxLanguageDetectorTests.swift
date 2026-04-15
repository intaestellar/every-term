import Testing
@testable import EveryTerm

@Suite("SyntaxLanguageDetector Tests")
struct SyntaxLanguageDetectorTests {

    // MARK: - [쉬움] 확장자 → 언어 매핑

    @Test(".sh → Shell로 매핑되어야 한다")
    func shMapsToShell() {
        let language = SyntaxLanguageDetector.detect(filename: "script.sh")
        #expect(language == .shell)
    }

    @Test(".py → Python으로 매핑되어야 한다")
    func pyMapsToPython() {
        let language = SyntaxLanguageDetector.detect(filename: "main.py")
        #expect(language == .python)
    }

    @Test(".js → JavaScript로 매핑되어야 한다")
    func jsMapsToJavaScript() {
        let language = SyntaxLanguageDetector.detect(filename: "app.js")
        #expect(language == .javascript)
    }

    @Test(".ts → TypeScript로 매핑되어야 한다")
    func tsMapsToTypeScript() {
        let language = SyntaxLanguageDetector.detect(filename: "index.ts")
        #expect(language == .typescript)
    }

    @Test(".json → JSON으로 매핑되어야 한다")
    func jsonMapsToJSON() {
        let language = SyntaxLanguageDetector.detect(filename: "config.json")
        #expect(language == .json)
    }

    @Test(".yaml → YAML로 매핑되어야 한다")
    func yamlMapsToYAML() {
        let language = SyntaxLanguageDetector.detect(filename: "config.yaml")
        #expect(language == .yaml)
    }

    @Test(".yml → YAML로 매핑되어야 한다")
    func ymlMapsToYAML() {
        let language = SyntaxLanguageDetector.detect(filename: "docker-compose.yml")
        #expect(language == .yaml)
    }

    @Test(".toml → TOML로 매핑되어야 한다")
    func tomlMapsToTOML() {
        let language = SyntaxLanguageDetector.detect(filename: "Cargo.toml")
        #expect(language == .toml)
    }

    @Test(".xml → XML로 매핑되어야 한다")
    func xmlMapsToXML() {
        let language = SyntaxLanguageDetector.detect(filename: "pom.xml")
        #expect(language == .xml)
    }

    @Test(".sql → SQL로 매핑되어야 한다")
    func sqlMapsToSQL() {
        let language = SyntaxLanguageDetector.detect(filename: "schema.sql")
        #expect(language == .sql)
    }

    @Test(".go → Go로 매핑되어야 한다")
    func goMapsToGo() {
        let language = SyntaxLanguageDetector.detect(filename: "main.go")
        #expect(language == .go)
    }

    @Test(".rs → Rust로 매핑되어야 한다")
    func rsMapsToRust() {
        let language = SyntaxLanguageDetector.detect(filename: "lib.rs")
        #expect(language == .rust)
    }

    @Test(".java → Java로 매핑되어야 한다")
    func javaMapsToJava() {
        let language = SyntaxLanguageDetector.detect(filename: "Main.java")
        #expect(language == .java)
    }

    @Test(".c → C로 매핑되어야 한다")
    func cMapsToC() {
        let language = SyntaxLanguageDetector.detect(filename: "main.c")
        #expect(language == .c)
    }

    @Test(".h → C로 매핑되어야 한다")
    func hMapsToC() {
        let language = SyntaxLanguageDetector.detect(filename: "header.h")
        #expect(language == .c)
    }

    @Test(".cpp → C++로 매핑되어야 한다")
    func cppMapsToCpp() {
        let language = SyntaxLanguageDetector.detect(filename: "main.cpp")
        #expect(language == .cpp)
    }

    // MARK: - [쉬움] 특수 파일명 매핑

    @Test("Dockerfile → Docker로 매핑되어야 한다")
    func dockerfileMapsToDocker() {
        let language = SyntaxLanguageDetector.detect(filename: "Dockerfile")
        #expect(language == .docker)
    }

    @Test("Makefile → Makefile로 매핑되어야 한다")
    func makefileMapsToMakefile() {
        let language = SyntaxLanguageDetector.detect(filename: "Makefile")
        #expect(language == .makefile)
    }

    @Test(".conf → Config로 매핑되어야 한다")
    func confMapsToConfig() {
        let language = SyntaxLanguageDetector.detect(filename: "nginx.conf")
        #expect(language == .config)
    }

    // MARK: - [보통] 알 수 없는 확장자

    @Test("알 수 없는 확장자는 plaintext로 매핑되어야 한다")
    func unknownExtensionMapsToPlaintext() {
        let language = SyntaxLanguageDetector.detect(filename: "file.xyz")
        #expect(language == .plaintext)
    }

    @Test("확장자가 없는 파일은 plaintext로 매핑되어야 한다")
    func noExtensionMapsToPlaintext() {
        let language = SyntaxLanguageDetector.detect(filename: "README")
        // Dockerfile, Makefile 등 특수 파일명이 아닌 경우 plaintext
        #expect(language == .plaintext)
    }

    // MARK: - [보통] 읽기 전용 판별 (에디터 연동)

    @Test("permissions & 0o200 == 0이면 읽기 전용으로 판별해야 한다")
    func readOnlyPermissions() {
        let isReadOnly = SyntaxLanguageDetector.isReadOnly(permissions: 0o100444)
        #expect(isReadOnly == true)
    }

    @Test("permissions & 0o200 != 0이면 편집 가능으로 판별해야 한다")
    func writablePermissions() {
        let isReadOnly = SyntaxLanguageDetector.isReadOnly(permissions: 0o100644)
        #expect(isReadOnly == false)
    }
}
