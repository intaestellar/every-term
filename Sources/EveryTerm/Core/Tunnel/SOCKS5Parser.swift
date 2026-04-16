import Foundation

public enum SOCKS5ParseError: Error, Sendable {
    case incompletePacket
    case unsupportedVersion
    case unsupportedAddressType
    case invalidData
}

public struct SOCKS5HandshakeResult: Sendable {
    public let version: UInt8
    public let methods: [UInt8]
}

public struct SOCKS5ConnectRequest: Sendable {
    public let host: String
    public let port: Int
}

public struct SOCKS5AuthCredentials: Sendable {
    public let username: String
    public let password: String
}

public enum SOCKS5Parser {

    public static func parseHandshake(_ data: Data) throws -> SOCKS5HandshakeResult {
        guard data.count >= 2 else {
            throw SOCKS5ParseError.incompletePacket
        }

        let version = data[data.startIndex]
        guard version == 0x05 else {
            throw SOCKS5ParseError.unsupportedVersion
        }
        let methodCount = data[data.startIndex + 1]

        guard data.count >= 2 + Int(methodCount) else {
            throw SOCKS5ParseError.incompletePacket
        }

        var methods: [UInt8] = []
        for i in 0..<Int(methodCount) {
            methods.append(data[data.startIndex + 2 + i])
        }

        return SOCKS5HandshakeResult(version: version, methods: methods)
    }

    public static func buildHandshakeResponse(method: UInt8) -> Data {
        return Data([0x05, method])
    }

    public static func parseConnectRequest(_ data: Data) throws -> SOCKS5ConnectRequest {
        // VER(1) + CMD(1) + RSV(1) + ATYP(1) = 4 bytes minimum
        guard data.count >= 4 else {
            throw SOCKS5ParseError.incompletePacket
        }

        let ver = data[data.startIndex]
        let cmd = data[data.startIndex + 1]
        guard ver == 0x05 else { throw SOCKS5ParseError.unsupportedVersion }
        guard cmd == 0x01 else { throw SOCKS5ParseError.invalidData }

        let atyp = data[data.startIndex + 3]
        let host: String
        let portOffset: Int

        switch atyp {
        case 0x01: // IPv4
            guard data.count >= 10 else {
                throw SOCKS5ParseError.incompletePacket
            }
            let a = data[data.startIndex + 4]
            let b = data[data.startIndex + 5]
            let c = data[data.startIndex + 6]
            let d = data[data.startIndex + 7]
            host = "\(a).\(b).\(c).\(d)"
            portOffset = 8

        case 0x03: // Domain
            guard data.count >= 5 else {
                throw SOCKS5ParseError.incompletePacket
            }
            let domainLen = Int(data[data.startIndex + 4])
            guard data.count >= 5 + domainLen + 2 else {
                throw SOCKS5ParseError.incompletePacket
            }
            let domainBytes = data[(data.startIndex + 5)..<(data.startIndex + 5 + domainLen)]
            host = String(data: Data(domainBytes), encoding: .utf8) ?? ""
            portOffset = 5 + domainLen

        default:
            throw SOCKS5ParseError.unsupportedAddressType
        }

        guard data.count >= portOffset + 2 else {
            throw SOCKS5ParseError.incompletePacket
        }

        let port = Int(data[data.startIndex + portOffset]) << 8 | Int(data[data.startIndex + portOffset + 1])

        return SOCKS5ConnectRequest(host: host, port: port)
    }

    public static func buildConnectResponse(success: Bool) -> Data {
        // VER(1) + REP(1) + RSV(1) + ATYP(1) + BND.ADDR(4) + BND.PORT(2) = 10 bytes
        let rep: UInt8 = success ? 0x00 : 0x01
        return Data([
            0x05,   // VER
            rep,    // REP
            0x00,   // RSV
            0x01,   // ATYP = IPv4
            0x00, 0x00, 0x00, 0x00,  // BND.ADDR
            0x00, 0x00               // BND.PORT
        ])
    }

    public static func parseUsernamePassword(_ data: Data) throws -> SOCKS5AuthCredentials {
        // VER(1) + ULEN(1) + UNAME(ULEN) + PLEN(1) + PASSWD(PLEN)
        guard data.count >= 2 else {
            throw SOCKS5ParseError.incompletePacket
        }

        let ulen = Int(data[data.startIndex + 1])
        guard data.count >= 2 + ulen + 1 else {
            throw SOCKS5ParseError.incompletePacket
        }

        let usernameBytes = data[(data.startIndex + 2)..<(data.startIndex + 2 + ulen)]
        let username = String(data: Data(usernameBytes), encoding: .utf8) ?? ""

        let plenIndex = data.startIndex + 2 + ulen
        let plen = Int(data[plenIndex])
        guard data.count >= 2 + ulen + 1 + plen else {
            throw SOCKS5ParseError.incompletePacket
        }

        let passwordBytes = data[(plenIndex + 1)..<(plenIndex + 1 + plen)]
        let password = String(data: Data(passwordBytes), encoding: .utf8) ?? ""

        return SOCKS5AuthCredentials(username: username, password: password)
    }
}
