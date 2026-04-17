import Foundation

/// Value object describing Sparkle-style auto update settings.
///
/// The concrete updater (`SPUStandardUpdaterController`) is injected elsewhere;
/// this struct carries only the settings so it can be serialised, defaulted,
/// and unit-tested without the Sparkle dependency.
public struct UpdateConfiguration: Sendable, Equatable, Codable {
    public let feedURL: URL
    public let automaticCheckEnabled: Bool
    public let checkInterval: TimeInterval
    public let publicEDKey: String

    public init(
        feedURL: URL,
        automaticCheckEnabled: Bool,
        checkInterval: TimeInterval,
        publicEDKey: String
    ) {
        self.feedURL = feedURL
        self.automaticCheckEnabled = automaticCheckEnabled
        // Clamp non-positive intervals to the default 24h to keep Sparkle happy.
        self.checkInterval = checkInterval > 0 ? checkInterval : Self.defaultInterval
        self.publicEDKey = publicEDKey
    }

    public static let defaultInterval: TimeInterval = 86_400

    public static let `default` = UpdateConfiguration(
        feedURL: URL(string: "https://github.com/everyterm/everyterm/releases/appcast.xml")!,
        automaticCheckEnabled: true,
        checkInterval: defaultInterval,
        // Placeholder — the real EdDSA public key is injected by
        // Scripts/generate-appcast.sh at release time.
        // While empty, automatic update checks are effectively disabled.
        publicEDKey: ""
    )
}
