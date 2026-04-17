import Foundation

/// Deferred update controller — Sparkle is **not yet integrated**.
///
/// Sparkle SPM dependency is commented out in ``Package.swift``; this type
/// delegates to ``MockUpdateController`` so the menu bar / preferences
/// window can compile against ``UpdateControllerProtocol`` today.
///
/// When the release-signing pipeline is ready:
/// 1. Uncomment the Sparkle dependency in `Package.swift`.
/// 2. Rename this class back to `SparkleUpdateController`.
/// 3. Replace the forwarding body with `SPUStandardUpdaterController`.
@MainActor
public final class DeferredUpdateController: UpdateControllerProtocol {
    private let delegate: UpdateControllerProtocol
    public let configuration: UpdateConfiguration

    public var isAutomaticallyCheckingForUpdates: Bool {
        get { delegate.isAutomaticallyCheckingForUpdates }
        set { delegate.isAutomaticallyCheckingForUpdates = newValue }
    }

    public init(
        configuration: UpdateConfiguration = .default,
        delegate: UpdateControllerProtocol? = nil
    ) {
        self.configuration = configuration
        self.delegate = delegate ?? MockUpdateController(
            isAutomaticallyCheckingForUpdates: configuration.automaticCheckEnabled
        )
    }

    public func checkForUpdates() {
        delegate.checkForUpdates()
    }
}

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
