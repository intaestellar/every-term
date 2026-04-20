import Foundation

public enum SessionType: String, CaseIterable, Codable, Sendable {
    case ssh
    case local
    case rdp
    case vnc
    case telnet
    case serial

    public var isAvailable: Bool {
        switch self {
        case .rdp, .vnc:
            return false
        case .ssh, .local, .telnet, .serial:
            return true
        }
    }
}

public enum AuthMethod: String, CaseIterable, Codable, Sendable {
    case password
    case key
    case agent
    case interactive
}
