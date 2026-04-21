import Foundation

// MARK: - Telnet Commands (RFC 854)

public enum TelnetCommand: UInt8, Sendable {
    case iac = 255
    case will = 251
    case wont = 252
    case doCmd = 253
    case dont = 254
    case sb = 250
    case se = 240
}

public enum TelnetOption: UInt8, Sendable {
    case echo = 1
    case sga = 3
    case ttype = 24
    case naws = 31
}

// MARK: - Parsed Command

public enum TelnetParsedCommand: Sendable, Equatable {
    case will(TelnetOption)
    case wont(TelnetOption)
    case doOption(TelnetOption)
    case dont(TelnetOption)
    case subnegotiation(TelnetOption, Data)
}

// MARK: - Parser Result

public struct TelnetParseResult: Sendable, Equatable {
    public var data: Data
    public var commands: [TelnetParsedCommand]

    public init(data: Data = Data(), commands: [TelnetParsedCommand] = []) {
        self.data = data
        self.commands = commands
    }
}

// MARK: - Streaming Parser

public struct TelnetParser: Sendable {
    // FIX-4: 악성/버그 서버가 IAC SE 를 전혀 보내지 않고 SB 바이트만 흘려 메모리 고갈시키는
    // 상황을 차단하기 위해 sub-negotiation 버퍼 상한을 둔다.
    public static let maxSubnegotiationSize: Int = 4096

    private enum State: Sendable {
        case data
        case iacSeen
        case willSeen
        case wontSeen
        case doSeen
        case dontSeen
        case sbSeen
        case sbCollecting(option: UInt8, buffer: Data)
        case sbIacSeen(option: UInt8, buffer: Data)
    }

    private var state: State = .data

    public init() {}

    public mutating func feed(_ input: Data) -> TelnetParseResult {
        var output = Data()
        var commands: [TelnetParsedCommand] = []

        for byte in input {
            switch state {
            case .data:
                if byte == TelnetCommand.iac.rawValue {
                    state = .iacSeen
                } else {
                    output.append(byte)
                }

            case .iacSeen:
                if byte == TelnetCommand.iac.rawValue {
                    // Escaped 0xFF
                    output.append(0xFF)
                    state = .data
                } else if byte == TelnetCommand.will.rawValue {
                    state = .willSeen
                } else if byte == TelnetCommand.wont.rawValue {
                    state = .wontSeen
                } else if byte == TelnetCommand.doCmd.rawValue {
                    state = .doSeen
                } else if byte == TelnetCommand.dont.rawValue {
                    state = .dontSeen
                } else if byte == TelnetCommand.sb.rawValue {
                    state = .sbSeen
                } else {
                    // Unknown command, return to data state
                    state = .data
                }

            case .willSeen:
                if let opt = TelnetOption(rawValue: byte) {
                    commands.append(.will(opt))
                }
                state = .data

            case .wontSeen:
                if let opt = TelnetOption(rawValue: byte) {
                    commands.append(.wont(opt))
                }
                state = .data

            case .doSeen:
                if let opt = TelnetOption(rawValue: byte) {
                    commands.append(.doOption(opt))
                }
                state = .data

            case .dontSeen:
                if let opt = TelnetOption(rawValue: byte) {
                    commands.append(.dont(opt))
                }
                state = .data

            case .sbSeen:
                state = .sbCollecting(option: byte, buffer: Data())

            case .sbCollecting(let option, var buffer):
                if byte == TelnetCommand.iac.rawValue {
                    state = .sbIacSeen(option: option, buffer: buffer)
                } else {
                    // FIX-4: SB 버퍼 상한. 초과 시 현재 subnegotiation 전체를 폐기하고
                    // data state 로 복귀 (IAC SE 를 영원히 기다리지 않도록).
                    if buffer.count >= TelnetParser.maxSubnegotiationSize {
                        // Drop oversized subnegotiation payload; consumers should observe
                        // no .subnegotiation event for this OPTION (DoS mitigation).
                        state = .data
                    } else {
                        buffer.append(byte)
                        state = .sbCollecting(option: option, buffer: buffer)
                    }
                }

            case .sbIacSeen(let option, var buffer):
                if byte == TelnetCommand.se.rawValue {
                    if let opt = TelnetOption(rawValue: option) {
                        commands.append(.subnegotiation(opt, buffer))
                    }
                    state = .data
                } else if byte == TelnetCommand.iac.rawValue {
                    // Escaped IAC within subnegotiation
                    if buffer.count >= TelnetParser.maxSubnegotiationSize {
                        // FIX-4: 상한 도달 → SB payload 전체 폐기.
                        state = .data
                    } else {
                        buffer.append(0xFF)
                        state = .sbCollecting(option: option, buffer: buffer)
                    }
                } else {
                    // Abort subnegotiation; discard partial buffer
                    state = .data
                }
            }
        }

        return TelnetParseResult(data: output, commands: commands)
    }
}

// MARK: - Protocol Helpers

public enum TelnetProtocol {
    public static func buildNAWSSubnegotiation(width: Int, height: Int) -> Data {
        var data = Data()
        data.append(TelnetCommand.iac.rawValue)
        data.append(TelnetCommand.sb.rawValue)
        data.append(TelnetOption.naws.rawValue)
        let w = UInt16(width)
        let h = UInt16(height)
        data.append(UInt8((w >> 8) & 0xFF))
        data.append(UInt8(w & 0xFF))
        data.append(UInt8((h >> 8) & 0xFF))
        data.append(UInt8(h & 0xFF))
        data.append(TelnetCommand.iac.rawValue)
        data.append(TelnetCommand.se.rawValue)
        return data
    }
}

// MARK: - Option Negotiator (Q Method subset)

public actor TelnetOptionNegotiator {
    // Remote side asked us to DO (turn on our side): track options we've agreed to advertise WILL for.
    private var agreedLocal: Set<TelnetOption> = []
    // Options remote is supporting (they sent WILL and we replied DO): track DO-agreed.
    private var agreedRemote: Set<TelnetOption> = []

    public init() {}

    public func respond(to command: TelnetParsedCommand) -> Data {
        switch command {
        case .doOption(let opt):
            // Local WILL response if we're willing to support.
            guard supportsLocal(opt) else {
                return Data([
                    TelnetCommand.iac.rawValue,
                    TelnetCommand.wont.rawValue,
                    opt.rawValue
                ])
            }
            if agreedLocal.contains(opt) {
                // Already agreed — Q Method: do not reply.
                return Data()
            }
            agreedLocal.insert(opt)
            return Data([
                TelnetCommand.iac.rawValue,
                TelnetCommand.will.rawValue,
                opt.rawValue
            ])

        case .dont(let opt):
            if agreedLocal.contains(opt) {
                agreedLocal.remove(opt)
                return Data([
                    TelnetCommand.iac.rawValue,
                    TelnetCommand.wont.rawValue,
                    opt.rawValue
                ])
            }
            return Data()

        case .will(let opt):
            guard supportsRemote(opt) else {
                return Data([
                    TelnetCommand.iac.rawValue,
                    TelnetCommand.dont.rawValue,
                    opt.rawValue
                ])
            }
            if agreedRemote.contains(opt) {
                return Data()
            }
            agreedRemote.insert(opt)
            return Data([
                TelnetCommand.iac.rawValue,
                TelnetCommand.doCmd.rawValue,
                opt.rawValue
            ])

        case .wont(let opt):
            if agreedRemote.contains(opt) {
                agreedRemote.remove(opt)
                return Data([
                    TelnetCommand.iac.rawValue,
                    TelnetCommand.dont.rawValue,
                    opt.rawValue
                ])
            }
            return Data()

        case .subnegotiation:
            return Data()
        }
    }

    private func supportsLocal(_ opt: TelnetOption) -> Bool {
        switch opt {
        case .naws, .ttype, .sga:
            return true
        case .echo:
            return false
        }
    }

    private func supportsRemote(_ opt: TelnetOption) -> Bool {
        switch opt {
        case .echo, .sga:
            return true
        case .naws, .ttype:
            return false
        }
    }
}
