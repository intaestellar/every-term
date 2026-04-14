import Foundation

public final class TerminalBufferManager: @unchecked Sendable {
    public let perTabLineLimit: Int
    public let appMemoryLimitBytes: Int
    public let inactiveTabMinLines: Int

    // Using a class wrapper for mutable state since we need Sendable
    private let _state = BufferState()

    public init(
        perTabLineLimit: Int = 10_000,
        appMemoryLimitBytes: Int = 200 * 1024 * 1024,
        inactiveTabMinLines: Int = 1_000
    ) {
        self.perTabLineLimit = perTabLineLimit
        self.appMemoryLimitBytes = appMemoryLimitBytes
        self.inactiveTabMinLines = inactiveTabMinLines
    }

    public func appendLine(_ line: String, toTab tabId: UUID) {
        _state.lock.lock()
        defer { _state.lock.unlock() }

        if _state.buffers[tabId] == nil {
            _state.buffers[tabId] = []
            _state.accessOrder.append(tabId)
        }
        _state.buffers[tabId]!.append(line)

        // Enforce per-tab limit
        if _state.buffers[tabId]!.count > perTabLineLimit {
            let excess = _state.buffers[tabId]!.count - perTabLineLimit
            _state.buffers[tabId]!.removeFirst(excess)
        }
    }

    public func lineCount(forTab tabId: UUID) -> Int {
        _state.lock.lock()
        defer { _state.lock.unlock() }
        return _state.buffers[tabId]?.count ?? 0
    }

    public func line(at index: Int, forTab tabId: UUID) -> String? {
        _state.lock.lock()
        defer { _state.lock.unlock() }
        guard let buffer = _state.buffers[tabId], index < buffer.count else { return nil }
        return buffer[index]
    }

    public func setActiveTab(_ tabId: UUID) {
        _state.lock.lock()
        defer { _state.lock.unlock() }
        _state.activeTab = tabId
    }

    public func markAccessed(tab tabId: UUID) {
        _state.lock.lock()
        defer { _state.lock.unlock() }
        // Move to end of access order (most recently accessed)
        _state.accessOrder.removeAll { $0 == tabId }
        _state.accessOrder.append(tabId)
    }

    public func checkMemoryPressure() {
        _state.lock.lock()
        defer { _state.lock.unlock() }

        var totalMemory = estimateMemoryLocked()

        if totalMemory <= appMemoryLimitBytes { return }

        // Shrink inactive tabs in LRU order (oldest first)
        for tabId in _state.accessOrder {
            if tabId == _state.activeTab { continue }
            guard var buffer = _state.buffers[tabId] else { continue }

            if buffer.count > inactiveTabMinLines {
                let excess = buffer.count - inactiveTabMinLines
                buffer.removeFirst(excess)
                _state.buffers[tabId] = buffer
            }

            totalMemory = estimateMemoryLocked()
            if totalMemory <= appMemoryLimitBytes { break }
        }
    }

    private func estimateMemoryLocked() -> Int {
        var total = 0
        for (_, buffer) in _state.buffers {
            for line in buffer {
                total += line.utf8.count
            }
        }
        return total
    }
}

// Internal mutable state wrapper
private final class BufferState: @unchecked Sendable {
    let lock = NSLock()
    var buffers: [UUID: [String]] = [:]
    var activeTab: UUID?
    var accessOrder: [UUID] = []
}
