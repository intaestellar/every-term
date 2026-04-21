import Foundation
import SwiftData

@Model
public final class RDPSessionConfig: @unchecked Sendable {
    public var id: UUID
    public var sessionId: UUID
    public var domain: String?
    public var width: Int?
    public var height: Int?
    public var colorDepth: Int
    public var enableClipboard: Bool
    public var enableDriveRedirect: Bool
    public var sharedFolderPath: String?
    public var enableAudio: Bool
    public var gatewayHost: String?
    public var gatewayPort: Int?
    public var gatewayUsername: String?
    public var useNLA: Bool

    public init(
        sessionId: UUID,
        domain: String? = nil,
        width: Int? = nil,
        height: Int? = nil,
        colorDepth: Int = 24,
        enableClipboard: Bool = true,
        enableDriveRedirect: Bool = false,
        sharedFolderPath: String? = nil,
        enableAudio: Bool = true,
        gatewayHost: String? = nil,
        gatewayPort: Int? = nil,
        gatewayUsername: String? = nil,
        useNLA: Bool = true
    ) {
        self.id = UUID()
        self.sessionId = sessionId
        self.domain = domain
        self.width = width
        self.height = height
        self.colorDepth = colorDepth
        self.enableClipboard = enableClipboard
        self.enableDriveRedirect = enableDriveRedirect
        self.sharedFolderPath = sharedFolderPath
        self.enableAudio = enableAudio
        self.gatewayHost = gatewayHost
        self.gatewayPort = gatewayPort
        self.gatewayUsername = gatewayUsername
        self.useNLA = useNLA
    }
}
