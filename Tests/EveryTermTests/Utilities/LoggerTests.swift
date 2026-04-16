import Testing
@testable import EveryTerm

@Suite("Logger Tests")
struct LoggerTests {

    @Test("Logger 생성 후 기본 로그 레벨 확인")
    func defaultLogLevel() {
        let logger = AppLogger()
        #expect(logger.logLevel == .info)
    }

    @Test("debug 레벨 로그 기록 — 크래시 없음")
    func debugLog() {
        let logger = AppLogger()
        logger.debug("Debug message")
    }

    @Test("info 레벨 로그 기록 — 크래시 없음")
    func infoLog() {
        let logger = AppLogger()
        logger.info("Info message")
    }

    @Test("warning 레벨 로그 기록 — 크래시 없음")
    func warningLog() {
        let logger = AppLogger()
        logger.warning("Warning message")
    }

    @Test("error 레벨 로그 기록 — 크래시 없음")
    func errorLog() {
        let logger = AppLogger()
        logger.error("Error message")
    }
}
