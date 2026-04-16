import Foundation
import SwiftData

public enum TunnelType: String, Codable, Sendable {
    case local
    case remote
    case dynamic
}

@Model
public final class TunnelConfig: @unchecked Sendable {
    public var id: UUID
    public var name: String
    public var sessionId: UUID
    public var type: TunnelType
    public var localHost: String
    public var localPort: Int
    public var remoteHost: String
    public var remotePort: Int
    public var isAutoStart: Bool
    public var isEnabled: Bool
    public var createdAt: Date

    public init(
        name: String,
        sessionId: UUID,
        type: TunnelType,
        localPort: Int,
        remoteHost: String,
        remotePort: Int,
        localHost: String = "127.0.0.1",
        isAutoStart: Bool = false,
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.sessionId = sessionId
        self.type = type
        self.localHost = localHost
        self.localPort = localPort
        self.remoteHost = remoteHost
        self.remotePort = remotePort
        self.isAutoStart = isAutoStart
        self.isEnabled = isEnabled
        self.createdAt = Date()
    }
}
