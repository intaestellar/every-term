import Testing
import Foundation
@testable import EveryTerm

// NOTE: Integration test — requires Sparkle framework
@Suite("SparkleUpdateController Tests")
@MainActor
struct SparkleUpdateControllerTests {

    // MARK: - [쉬움] 프로토콜 준수

    @Test(.disabled("Requires code-signed app bundle"))
    func conformsToUpdateControllerProtocol() {
        let ctrl: any UpdateControllerProtocol = SparkleUpdateController(configuration: .default)
        _ = ctrl
    }

    // MARK: - [쉬움] configuration 저장

    @Test(.disabled("Requires code-signed app bundle"))
    func configuration_storesFeedURL() {
        let config = UpdateConfiguration.default
        let ctrl = SparkleUpdateController(configuration: config)
        #expect(ctrl.configuration.feedURL == config.feedURL)
    }

    // MARK: - [쉬움] MainActor 격리

    @Test(.disabled("Requires code-signed app bundle"))
    func mainActorIsolation() {
        let ctrl = SparkleUpdateController(configuration: .default)
        _ = ctrl.isAutomaticallyCheckingForUpdates
    }

    // MARK: - [보통] isAutoCheck 초기값

    @Test(.disabled("Requires code-signed app bundle"))
    func isAutoCheck_initialValue_matchesConfig() {
        let config = UpdateConfiguration.default
        let ctrl = SparkleUpdateController(configuration: config)
        #expect(ctrl.isAutomaticallyCheckingForUpdates == config.automaticCheckEnabled)
    }

    // MARK: - [보통] isAutoCheck setter

    @Test(.disabled("Requires code-signed app bundle"))
    func isAutoCheck_setter_roundTrip() {
        let ctrl = SparkleUpdateController(configuration: .default)
        ctrl.isAutomaticallyCheckingForUpdates = false
        #expect(ctrl.isAutomaticallyCheckingForUpdates == false)
        ctrl.isAutomaticallyCheckingForUpdates = true
        #expect(ctrl.isAutomaticallyCheckingForUpdates == true)
    }

    // MARK: - [보통] checkForUpdates crash 없음

    @Test(.disabled("Requires code-signed app bundle"))
    func checkForUpdates_doesNotCrash() {
        let ctrl = SparkleUpdateController(configuration: .default)
        ctrl.checkForUpdates()
    }

    // MARK: - [어려움] 커스텀 feedURL

    @Test(.disabled("Requires code-signed app bundle"))
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
