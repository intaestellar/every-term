import Foundation
import Sparkle

/// Sparkle-based update controller wrapping `SPUStandardUpdaterController`.
///
/// This is the production implementation of ``UpdateControllerProtocol``.
/// It initialises Sparkle's standard updater with the feed URL and check
/// interval from ``UpdateConfiguration``.
public typealias SparkleUpdateController = LiveUpdateController

@MainActor
public final class LiveUpdateController: UpdateControllerProtocol {
    public let configuration: UpdateConfiguration
    private let updaterController: SPUStandardUpdaterController

    public var isAutomaticallyCheckingForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }

    public init(
        configuration: UpdateConfiguration = .default,
        delegate: UpdateControllerProtocol? = nil
    ) {
        self.configuration = configuration
        // Start with updater inactive; the host app calls
        // `checkForUpdates()` or enables automatic checks explicitly.
        self.updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        updaterController.updater.automaticallyChecksForUpdates = configuration.automaticCheckEnabled
        updaterController.updater.updateCheckInterval = configuration.checkInterval
    }

    public func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}

/// Kept for backward compatibility — aliases to LiveUpdateController.
public typealias DeferredUpdateController = LiveUpdateController

/// In-memory stand-in for `SPUStandardUpdaterController`. Tracks the
/// "automatic check" toggle and counts manual invocations so tests can
/// assert without pulling in Sparkle.
@MainActor
public final class MockUpdateController: UpdateControllerProtocol {
    public var isAutomaticallyCheckingForUpdates: Bool
    public private(set) var manualCheckCount: Int = 0
    public var onCheckForUpdates: (() -> Void)?

    public init(
        isAutomaticallyCheckingForUpdates: Bool = true,
        onCheckForUpdates: (() -> Void)? = nil
    ) {
        self.isAutomaticallyCheckingForUpdates = isAutomaticallyCheckingForUpdates
        self.onCheckForUpdates = onCheckForUpdates
    }

    public func checkForUpdates() {
        manualCheckCount += 1
        onCheckForUpdates?()
    }
}
