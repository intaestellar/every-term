import Foundation
import Logging

public enum LogLevel: Int, Comparable, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var toSwiftLogLevel: Logger.Level {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .warning
        case .error: return .error
        }
    }
}

public struct AppLogger: Sendable {
    public let logLevel: LogLevel
    private let logger: Logger

    public init(logLevel: LogLevel = .info, label: String = "com.everyterm.app") {
        self.logLevel = logLevel
        self.logger = Logger(label: label)
    }

    public func debug(_ message: String) {
        log(message, level: .debug)
    }

    public func info(_ message: String) {
        log(message, level: .info)
    }

    public func warning(_ message: String) {
        log(message, level: .warning)
    }

    public func error(_ message: String) {
        log(message, level: .error)
    }

    private func log(_ message: String, level: LogLevel) {
        guard level >= logLevel else { return }
        logger.log(level: level.toSwiftLogLevel, "\(message)")
    }
}
