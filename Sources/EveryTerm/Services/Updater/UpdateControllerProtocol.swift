import Foundation

/// Thin facade over `SPUStandardUpdaterController` so UI and menu bar code can
/// be tested without the Sparkle SPM dependency being linked.
@MainActor
public protocol UpdateControllerProtocol: AnyObject {
    var isAutomaticallyCheckingForUpdates: Bool { get set }
    func checkForUpdates()
}
