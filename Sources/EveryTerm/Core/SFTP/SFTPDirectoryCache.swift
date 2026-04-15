import Foundation

/// TTL-based in-memory cache for SFTP directory listings.
public actor SFTPDirectoryCache {
    private let cache = NSCache<NSString, CachedDirectory>()
    private var timestamps: [String: Date] = [:]
    private let ttl: TimeInterval

    public init(ttl: TimeInterval = 30) {
        self.ttl = ttl
    }

    public func set(_ entries: [SFTPFileEntry], for path: String) {
        let cached = CachedDirectory(entries: entries)
        cache.setObject(cached, forKey: path as NSString)
        timestamps[path] = Date()
    }

    public func get(_ path: String) -> [SFTPFileEntry]? {
        guard let timestamp = timestamps[path] else { return nil }

        if Date().timeIntervalSince(timestamp) > ttl {
            cache.removeObject(forKey: path as NSString)
            timestamps.removeValue(forKey: path)
            return nil
        }

        return cache.object(forKey: path as NSString)?.entries
    }

    public func invalidate(path: String) {
        cache.removeObject(forKey: path as NSString)
        timestamps.removeValue(forKey: path)
    }

    public func invalidateAll() {
        cache.removeAllObjects()
        timestamps.removeAll()
    }
}

/// Wrapper for NSCache storage (NSCache requires NSObject values).
final class CachedDirectory: NSObject {
    let entries: [SFTPFileEntry]

    init(entries: [SFTPFileEntry]) {
        self.entries = entries
    }
}
