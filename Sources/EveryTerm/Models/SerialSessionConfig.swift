import Foundation
import SwiftData

public enum SerialParity: String, CaseIterable, Codable, Sendable {
    case none
    case even
    case odd
}

public enum SerialFlowControl: String, CaseIterable, Codable, Sendable {
    case none
    case hardware
    case software
}

@Model
public final class SerialSessionConfig: @unchecked Sendable {
    public var id: UUID
    public var sessionId: UUID
    public var devicePath: String
    public var baudRate: Int
    public var dataBits: Int
    public var stopBits: Int
    public var parityRaw: String
    public var flowControlRaw: String

    public init(
        sessionId: UUID,
        devicePath: String = "",
        baudRate: Int = 9600,
        dataBits: Int = 8,
        stopBits: Int = 1,
        parity: SerialParity = .none,
        flowControl: SerialFlowControl = .none
    ) {
        self.id = UUID()
        self.sessionId = sessionId
        self.devicePath = devicePath
        self.baudRate = baudRate
        self.dataBits = dataBits
        self.stopBits = stopBits
        self.parityRaw = parity.rawValue
        self.flowControlRaw = flowControl.rawValue
    }

    public static func isAllowedBaudRate(_ rate: Int) -> Bool {
        let allowed: Set<Int> = [9600, 19200, 38400, 57600, 115200]
        return allowed.contains(rate)
    }
}
