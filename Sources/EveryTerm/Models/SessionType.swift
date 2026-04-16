import Foundation

public enum SessionType: String, CaseIterable, Codable, Sendable {
    case ssh
    case local
    case rdp
    case vnc
    case telnet
    case serial
}

public enum AuthMethod: String, CaseIterable, Codable, Sendable {
    case password
    case key
    case agent
    case interactive
}
