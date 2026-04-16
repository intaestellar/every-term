import Foundation
import SwiftData

public enum VNCEncoding: String, CaseIterable, Codable, Sendable {
    case zrle
    case tight
    case copyRect
    case raw
}

public enum VNCScalingMode: String, CaseIterable, Codable, Sendable {
    case fit
    case scroll
    case native
}

@Model
public final class VNCSessionConfig: @unchecked Sendable {
    public var id: UUID
    public var sessionId: UUID
    public var port: Int
    public var encodingRaw: String
    public var viewOnly: Bool
    public var scalingModeRaw: String
    public var sshTunnelSessionId: UUID?

    public init(
        sessionId: UUID,
        port: Int = 5900,
        encoding: VNCEncoding = .zrle,
        viewOnly: Bool = false,
        scalingMode: VNCScalingMode = .fit,
        sshTunnelSessionId: UUID? = nil
    ) {
        self.id = UUID()
        self.sessionId = sessionId
        self.port = port
        self.encodingRaw = encoding.rawValue
        self.viewOnly = viewOnly
        self.scalingModeRaw = scalingMode.rawValue
        self.sshTunnelSessionId = sshTunnelSessionId
    }
}
