import Testing
import Foundation
@testable import EveryTerm

@Suite("RemoteConnectionError — unsupportedProtocol Tests")
struct RemoteConnectionErrorTests {

    // MARK: - [쉬움] unsupportedProtocol case 존재 확인

    @Test("unsupportedProtocol case가 존재하고 패턴매칭 가능")
    func unsupportedProtocol_case_exists() {
        let err = RemoteConnectionError.unsupportedProtocol
        switch err {
        case .unsupportedProtocol:
            break // 성공
        default:
            Issue.record("unsupportedProtocol case가 매칭되어야 한다")
        }
    }

    // MARK: - [쉬움] Sendable 준수

    @Test("unsupportedProtocol이 Sendable을 만족한다")
    func unsupportedProtocol_isSendable() {
        func requireSendable<T: Sendable>(_ t: T) {}
        requireSendable(RemoteConnectionError.unsupportedProtocol)
    }

    // MARK: - [쉬움] notImplemented case 유지 확인

    @Test("기존 notImplemented(String) case가 여전히 존재한다")
    func notImplemented_case_stillExists() {
        let err = RemoteConnectionError.notImplemented("test")
        switch err {
        case .notImplemented(let msg):
            #expect(msg == "test")
        default:
            Issue.record("notImplemented case가 매칭되어야 한다")
        }
    }

    // MARK: - [쉬움] unsupportedProtocol과 notImplemented 구분

    @Test("unsupportedProtocol과 notImplemented가 서로 다른 case로 구분된다")
    func unsupportedProtocol_and_notImplemented_areDifferent() {
        let errA = RemoteConnectionError.unsupportedProtocol
        let errB = RemoteConnectionError.notImplemented("RDP")

        var matchedA = false
        var matchedB = false

        switch errA {
        case .unsupportedProtocol:
            matchedA = true
        case .notImplemented:
            Issue.record("unsupportedProtocol이 notImplemented로 매칭되면 안 된다")
        default:
            Issue.record("알 수 없는 case")
        }

        switch errB {
        case .notImplemented:
            matchedB = true
        case .unsupportedProtocol:
            Issue.record("notImplemented가 unsupportedProtocol로 매칭되면 안 된다")
        default:
            Issue.record("알 수 없는 case")
        }

        #expect(matchedA)
        #expect(matchedB)
    }
}
