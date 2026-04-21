import Testing
import Foundation
@testable import EveryTerm

@Suite("UpdateControllerFacade Tests")
@MainActor
struct MockUpdateControllerTests {

    // MARK: - [쉬움] 프로토콜 시그니처

    @Test("UpdateControllerProtocol — checkForUpdates() / isAutomaticallyCheckingForUpdates 시그니처 컴파일")
    func protocolSignatures() {
        let mock: any UpdateControllerProtocol = MockUpdateController()
        mock.checkForUpdates()
        _ = mock.isAutomaticallyCheckingForUpdates
    }

    // MARK: - [보통] Mock 추적

    @Test("Mock 구현: checkForUpdates() 호출 횟수 추적")
    func checkForUpdatesCallCount() {
        let mock = MockUpdateController()
        #expect(mock.checkForUpdatesCallCount == 0)
        mock.checkForUpdates()
        #expect(mock.checkForUpdatesCallCount == 1)
        mock.checkForUpdates()
        #expect(mock.checkForUpdatesCallCount == 2)
    }

    @Test("isAutomaticallyCheckingForUpdates set/get 라운드트립")
    func isAutoCheckRoundTrip() {
        let mock = MockUpdateController()
        mock.isAutomaticallyCheckingForUpdates = false
        #expect(mock.isAutomaticallyCheckingForUpdates == false)
        mock.isAutomaticallyCheckingForUpdates = true
        #expect(mock.isAutomaticallyCheckingForUpdates == true)
    }
}

// MARK: - Mock

@MainActor
final class MockUpdateController: UpdateControllerProtocol {
    var checkForUpdatesCallCount: Int = 0
    var isAutomaticallyCheckingForUpdates: Bool = true

    func checkForUpdates() {
        checkForUpdatesCallCount += 1
    }
}
