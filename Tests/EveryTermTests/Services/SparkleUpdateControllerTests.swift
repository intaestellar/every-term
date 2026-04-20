import Testing
import Foundation
@testable import EveryTerm

@Suite("SparkleUpdateController Tests")
@MainActor
struct SparkleUpdateControllerTests {

    // MARK: - [쉬움] 프로토콜 준수

    @Test("SparkleUpdateController가 UpdateControllerProtocol을 준수한다")
    func conformsToUpdateControllerProtocol() {
        let ctrl: any UpdateControllerProtocol = SparkleUpdateController(configuration: .default)
        _ = ctrl
    }

    // MARK: - [쉬움] configuration 저장

    @Test("주입된 configuration의 feedURL이 정확히 보관된다")
    func configuration_storesFeedURL() {
        let config = UpdateConfiguration.default
        let ctrl = SparkleUpdateController(configuration: config)
        #expect(ctrl.configuration.feedURL == config.feedURL)
    }

    // MARK: - [쉬움] MainActor 격리

    @Test("@MainActor 테스트 내에서 직접 접근 가능 (컴파일 확인)")
    func mainActorIsolation() {
        let ctrl = SparkleUpdateController(configuration: .default)
        _ = ctrl.isAutomaticallyCheckingForUpdates
    }

    // MARK: - [보통] isAutoCheck 초기값

    @Test("isAutomaticallyCheckingForUpdates 초기값이 configuration.automaticCheckEnabled과 동기화")
    func isAutoCheck_initialValue_matchesConfig() {
        let config = UpdateConfiguration.default
        let ctrl = SparkleUpdateController(configuration: config)
        #expect(ctrl.isAutomaticallyCheckingForUpdates == config.automaticCheckEnabled)
    }

    // MARK: - [보통] isAutoCheck setter

    @Test("isAutomaticallyCheckingForUpdates set/get 라운드트립")
    func isAutoCheck_setter_roundTrip() {
        let ctrl = SparkleUpdateController(configuration: .default)
        ctrl.isAutomaticallyCheckingForUpdates = false
        #expect(ctrl.isAutomaticallyCheckingForUpdates == false)
        ctrl.isAutomaticallyCheckingForUpdates = true
        #expect(ctrl.isAutomaticallyCheckingForUpdates == true)
    }

    // MARK: - [보통] checkForUpdates crash 없음

    @Test("checkForUpdates() 호출 시 예외 없이 정상 리턴")
    func checkForUpdates_doesNotCrash() {
        let ctrl = SparkleUpdateController(configuration: .default)
        ctrl.checkForUpdates()
    }

    // MARK: - [어려움] 커스텀 feedURL

    @Test("커스텀 feedURL 주입 시에도 정상 초기화되고 feedURL 일치")
    func customFeedURL_initializesCorrectly() {
        let customURL = URL(string: "https://custom.example.com/appcast.xml")!
        let config = UpdateConfiguration(
            feedURL: customURL,
            automaticCheckEnabled: false,
            checkInterval: 3600,
            publicEDKey: "custom-key"
        )
        let ctrl = SparkleUpdateController(configuration: config)
        #expect(ctrl.configuration.feedURL == customURL)
        #expect(ctrl.configuration.automaticCheckEnabled == false)
        #expect(ctrl.configuration.checkInterval == 3600)
    }
}
