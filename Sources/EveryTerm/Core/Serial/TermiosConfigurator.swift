import Foundation
import Darwin

public enum TermiosError: Error {
    case unsupportedBaudRate(Int)
    case unsupportedDataBits(Int)
    case unsupportedStopBits(Int)
}

public enum TermiosConfigurator {

    public static func applyBaudRate(_ rate: Int, to t: inout Darwin.termios) throws {
        let speed: speed_t
        switch rate {
        case 9600: speed = speed_t(B9600)
        case 19200: speed = speed_t(B19200)
        case 38400: speed = speed_t(B38400)
        case 57600: speed = speed_t(B57600)
        case 115200: speed = speed_t(B115200)
        default:
            throw TermiosError.unsupportedBaudRate(rate)
        }
        _ = cfsetispeed(&t, speed)
        _ = cfsetospeed(&t, speed)
    }

    public static func applyFrameFormat(
        dataBits: Int,
        stopBits: Int,
        parity: SerialParity,
        to t: inout Darwin.termios
    ) throws {
        // Clear size bits first
        t.c_cflag &= ~tcflag_t(CSIZE)
        switch dataBits {
        case 5: t.c_cflag |= tcflag_t(CS5)
        case 6: t.c_cflag |= tcflag_t(CS6)
        case 7: t.c_cflag |= tcflag_t(CS7)
        case 8: t.c_cflag |= tcflag_t(CS8)
        default:
            throw TermiosError.unsupportedDataBits(dataBits)
        }

        switch stopBits {
        case 1:
            t.c_cflag &= ~tcflag_t(CSTOPB)
        case 2:
            t.c_cflag |= tcflag_t(CSTOPB)
        default:
            throw TermiosError.unsupportedStopBits(stopBits)
        }

        switch parity {
        case .none:
            t.c_cflag &= ~tcflag_t(PARENB)
            t.c_cflag &= ~tcflag_t(PARODD)
        case .even:
            t.c_cflag |= tcflag_t(PARENB)
            t.c_cflag &= ~tcflag_t(PARODD)
        case .odd:
            t.c_cflag |= tcflag_t(PARENB)
            t.c_cflag |= tcflag_t(PARODD)
        }
    }

    public static func applyFlowControl(_ fc: SerialFlowControl, to t: inout Darwin.termios) throws {
        switch fc {
        case .none:
            t.c_cflag &= ~tcflag_t(CRTSCTS)
            t.c_iflag &= ~tcflag_t(IXON)
            t.c_iflag &= ~tcflag_t(IXOFF)
        case .hardware:
            t.c_cflag |= tcflag_t(CRTSCTS)
            t.c_iflag &= ~tcflag_t(IXON)
            t.c_iflag &= ~tcflag_t(IXOFF)
        case .software:
            t.c_cflag &= ~tcflag_t(CRTSCTS)
            t.c_iflag |= tcflag_t(IXON)
            t.c_iflag |= tcflag_t(IXOFF)
        }
    }

    public static func applyRawMode(to t: inout Darwin.termios) throws {
        t.c_lflag &= ~tcflag_t(ICANON)
        t.c_lflag &= ~tcflag_t(ECHO)
        t.c_lflag &= ~tcflag_t(ECHOE)
        t.c_lflag &= ~tcflag_t(ECHONL)
        t.c_lflag &= ~tcflag_t(ISIG)
        t.c_iflag &= ~tcflag_t(IXON | IXOFF | IXANY)
        t.c_iflag &= ~tcflag_t(BRKINT | INLCR | ICRNL | ISTRIP)
        t.c_oflag &= ~tcflag_t(OPOST)
    }
}
