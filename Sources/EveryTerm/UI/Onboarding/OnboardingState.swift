import Foundation

public enum OnboardingStep: String, CaseIterable, Sendable, Equatable {
    case sshIntro
    case sftpSidebar
    case multiProtocol
}

@MainActor
public final class OnboardingState {
    public private(set) var currentStep: OnboardingStep
    public private(set) var hasCompletedOnboarding: Bool

    public init(
        currentStep: OnboardingStep = .sshIntro,
        hasCompletedOnboarding: Bool = false
    ) {
        self.currentStep = currentStep
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }

    public func advance() {
        switch currentStep {
        case .sshIntro:
            currentStep = .sftpSidebar
        case .sftpSidebar:
            currentStep = .multiProtocol
        case .multiProtocol:
            hasCompletedOnboarding = true
        }
    }

    public func skip() {
        hasCompletedOnboarding = true
    }

    public func reset() {
        currentStep = .sshIntro
        hasCompletedOnboarding = false
    }

}
