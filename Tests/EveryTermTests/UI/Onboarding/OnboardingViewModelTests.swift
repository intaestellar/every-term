import Testing
import Foundation
@testable import EveryTerm

// MARK: - OnboardingState Tests

@Suite("OnboardingState Tests")
@MainActor
struct OnboardingStateTests {

    // MARK: - [쉬움] enum 구조

    @Test("OnboardingStep enum 3개 케이스 (sshIntro/sftpSidebar/multiProtocol)")
    func onboardingStepAllCases() {
        #expect(OnboardingStep.allCases.count == 3)
        #expect(OnboardingStep.allCases.contains(.sshIntro))
        #expect(OnboardingStep.allCases.contains(.sftpSidebar))
        #expect(OnboardingStep.allCases.contains(.multiProtocol))
    }

    @Test("OnboardingStep rawValue 라운드트립")
    func onboardingStepRawValueRoundTrip() {
        for step in OnboardingStep.allCases {
            let restored = OnboardingStep(rawValue: step.rawValue)
            #expect(restored == step)
        }
    }

    @Test("초기 상태: currentStep == sshIntro, hasCompletedOnboarding == false")
    func initialState() {
        let state = OnboardingState()
        #expect(state.currentStep == .sshIntro)
        #expect(state.hasCompletedOnboarding == false)
    }

    // MARK: - [보통] 상태 전이

    @Test("advance() 호출 — sshIntro → sftpSidebar → multiProtocol 순차 전이")
    func advanceTransitions() {
        let state = OnboardingState()
        state.advance()
        #expect(state.currentStep == .sftpSidebar)
        state.advance()
        #expect(state.currentStep == .multiProtocol)
    }

    @Test("마지막 스텝에서 advance() 호출 시 hasCompletedOnboarding == true")
    func advanceAtLastStepCompletes() {
        let state = OnboardingState()
        state.advance() // sftpSidebar
        state.advance() // multiProtocol
        state.advance() // complete
        #expect(state.hasCompletedOnboarding == true)
    }

    @Test("skip() 호출 시 즉시 hasCompletedOnboarding == true")
    func skipMarksComplete() {
        let state = OnboardingState()
        state.skip()
        #expect(state.hasCompletedOnboarding == true)
    }

    @Test("reset() 호출 시 초기 상태로 복원")
    func resetRestoresInitial() {
        let state = OnboardingState()
        state.advance()
        state.skip()
        state.reset()
        #expect(state.currentStep == .sshIntro)
        #expect(state.hasCompletedOnboarding == false)
    }

}

// MARK: - WelcomeViewModel Tests

@Suite("WelcomeViewModel Tests")
@MainActor
struct WelcomeViewModelTests {

    // MARK: - [쉬움] 초기 상태

    @Test("세션 배열 비어있을 때 recentSessions.isEmpty == true")
    func emptySessionsEmptyRecent() {
        let vm = WelcomeViewModel(sessions: [])
        #expect(vm.recentSessions.isEmpty)
    }

    @Test("ctaButtons 에 '새 세션 만들기' + 'SSH Config 임포트' 포함")
    func ctaButtonsContent() {
        let vm = WelcomeViewModel(sessions: [])
        let titles = vm.ctaButtons.map(\.title)
        #expect(titles.contains("새 세션 만들기"))
        #expect(titles.contains("SSH Config 임포트"))
    }

    // MARK: - [보통] 정렬 / 카운트

    @Test("최근 세션 정렬: lastConnectedAt 내림차순")
    func recentSessionsDescendingByDate() {
        let now = Date()
        let s1 = Session(name: "A", type: .ssh, host: "a.com", username: "u", authMethod: .password, lastConnectedAt: now.addingTimeInterval(-100))
        let s2 = Session(name: "B", type: .ssh, host: "b.com", username: "u", authMethod: .password, lastConnectedAt: now)
        let s3 = Session(name: "C", type: .ssh, host: "c.com", username: "u", authMethod: .password, lastConnectedAt: now.addingTimeInterval(-50))

        let vm = WelcomeViewModel(sessions: [s1, s2, s3])
        let names = vm.recentSessions.map(\.name)
        #expect(names == ["B", "C", "A"])
    }

    @Test("11개 이상 세션 입력 시 recentSessions.count == 10")
    func recentSessionsCappedAt10() {
        let now = Date()
        let sessions = (0..<15).map { i in
            Session(
                name: "S\(i)",
                type: .ssh,
                host: "h.com",
                username: "u",
                authMethod: .password,
                lastConnectedAt: now.addingTimeInterval(TimeInterval(-i))
            )
        }
        let vm = WelcomeViewModel(sessions: sessions)
        #expect(vm.recentSessions.count == 10)
    }

    @Test("lastConnectedAt == nil 세션은 정렬 하위 배치")
    func nilLastConnectedAtSortedLast() {
        let s1 = Session(name: "A", type: .ssh, host: "a.com", username: "u", authMethod: .password, lastConnectedAt: nil)
        let s2 = Session(name: "B", type: .ssh, host: "b.com", username: "u", authMethod: .password, lastConnectedAt: Date())

        let vm = WelcomeViewModel(sessions: [s1, s2])
        let names = vm.recentSessions.map(\.name)
        #expect(names.first == "B")
        #expect(names.last == "A")
    }

    @Test("세션 0개일 때 shouldShowEmptyState == true")
    func emptyStateFlag() {
        let vm = WelcomeViewModel(sessions: [])
        #expect(vm.shouldShowEmptyState == true)
    }
}
