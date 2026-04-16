import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public final class SecureBytes: @unchecked Sendable {
    private let storage: UnsafeMutablePointer<UInt8>
    public let count: Int
    private let allocatedCapacity: Int

    public init() {
        self.count = 0
        self.allocatedCapacity = 1
        self.storage = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
    }

    public init(_ bytes: [UInt8]) {
        self.count = bytes.count
        if bytes.isEmpty {
            self.allocatedCapacity = 1
            self.storage = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
        } else {
            self.allocatedCapacity = bytes.count
            self.storage = UnsafeMutablePointer<UInt8>.allocate(capacity: bytes.count)
            self.storage.initialize(from: bytes, count: bytes.count)
        }
    }

    public init(utf8 string: String) {
        let bytes = Array(string.utf8)
        self.count = bytes.count
        if bytes.isEmpty {
            self.allocatedCapacity = 1
            self.storage = UnsafeMutablePointer<UInt8>.allocate(capacity: 1)
        } else {
            self.allocatedCapacity = bytes.count
            self.storage = UnsafeMutablePointer<UInt8>.allocate(capacity: bytes.count)
            self.storage.initialize(from: bytes, count: bytes.count)
        }
    }

    /// Scoped access to the underlying bytes. The pointer is only valid within the closure.
    public func withUnsafeBytes<T>(_ body: (UnsafeBufferPointer<UInt8>) throws -> T) rethrows -> T {
        try body(UnsafeBufferPointer(start: storage, count: count))
    }

    deinit {
        if count > 0 {
            // Use memset_s to prevent compiler Dead Store Elimination
            _ = memset_s(storage, count, 0, count)
        }
        storage.deallocate()
    }
}

extension SecureBytes: Sequence {
    public func makeIterator() -> IndexingIterator<[UInt8]> {
        var bytes = [UInt8](repeating: 0, count: count)
        for i in 0..<count {
            bytes[i] = storage[i]
        }
        return bytes.makeIterator()
    }
}
