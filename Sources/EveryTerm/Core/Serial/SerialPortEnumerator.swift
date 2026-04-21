import Foundation

public struct SerialPortInfo: Sendable, Equatable, Hashable {
    public let devicePath: String
    public let friendlyName: String
    public let vendorId: Int?
    public let productId: Int?

    public init(devicePath: String, friendlyName: String, vendorId: Int?, productId: Int?) {
        self.devicePath = devicePath
        self.friendlyName = friendlyName
        self.vendorId = vendorId
        self.productId = productId
    }
}

public struct SerialPortEnumerator: Sendable {
    public init() {}

    // MARK: - IOKit hotplug (TODO)
    //
    // The current implementation enumerates serial devices by scanning
    // `/dev/tty.*` and `/dev/cu.*` on demand. For live USB-Serial attach
    // and detach notifications we need to register an IOKit matching
    // callback against `kIOUSBDeviceClassName` / `IOSerialBSDClient`:
    //
    //   1. Create an `IONotificationPortRef` and schedule it on the
    //      main run loop (or a dedicated dispatch queue).
    //   2. Call `IOServiceAddMatchingNotification` with
    //      `kIOFirstMatchNotification` and `kIOTerminatedNotification`
    //      using a matching dictionary produced by
    //      `IOServiceMatching(kIOSerialBSDServiceValue)`.
    //   3. In the callback, iterate the returned `io_iterator_t` and
    //      emit `SerialPortInfo` values via an AsyncStream so the UI
    //      can refresh its list without polling.
    //
    // This is intentionally deferred to a follow-up task because the
    // bridging between CoreFoundation callbacks and Swift concurrency
    // requires careful isolation work that is out of scope for the
    // SP-4 multi-protocol completeness milestone.

    /// Deduplicate by `devicePath`, keeping first occurrence.
    func deduplicate(_ infos: [SerialPortInfo]) -> [SerialPortInfo] {
        var seen = Set<String>()
        var result: [SerialPortInfo] = []
        for info in infos {
            if !seen.contains(info.devicePath) {
                seen.insert(info.devicePath)
                result.append(info)
            }
        }
        return result
    }

    /// Enumerate serial ports by scanning /dev/tty.* and /dev/cu.* entries.
    /// Returns empty array on environments without serial devices.
    public func enumeratePorts() async -> [SerialPortInfo] {
        let fm = FileManager.default
        var results: [SerialPortInfo] = []
        let patterns = ["/dev/tty.", "/dev/cu."]

        do {
            let contents = try fm.contentsOfDirectory(atPath: "/dev")
            for name in contents {
                let fullPath = "/dev/" + name
                if patterns.contains(where: { fullPath.hasPrefix($0) }) {
                    let info = SerialPortInfo(
                        devicePath: fullPath,
                        friendlyName: name,
                        vendorId: nil,
                        productId: nil
                    )
                    results.append(info)
                }
            }
        } catch {
            return []
        }

        return deduplicate(results)
    }
}
