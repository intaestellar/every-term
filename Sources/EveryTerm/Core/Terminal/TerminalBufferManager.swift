import Foundation

public actor TerminalBufferManager {
    public let perTabLineLimit: Int
    public let appMemoryLimitBytes: Int
    public let inactiveTabMinLines: Int

    private var buffers: [UUID: [String]] = [:]
    private var activeTab: UUID?
    private var accessOrder: [UUID] = []

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
        if buffers[tabId] == nil {
            buffers[tabId] = []
            accessOrder.append(tabId)
        }
        buffers[tabId]!.append(line)

        // Enforce per-tab limit
        if buffers[tabId]!.count > perTabLineLimit {
            let excess = buffers[tabId]!.count - perTabLineLimit
            buffers[tabId]!.removeFirst(excess)
        }
    }

    public func lineCount(forTab tabId: UUID) -> Int {
        return buffers[tabId]?.count ?? 0
    }

    public func line(at index: Int, forTab tabId: UUID) -> String? {
        guard let buffer = buffers[tabId], index < buffer.count else { return nil }
        return buffer[index]
    }

    public func setActiveTab(_ tabId: UUID) {
        activeTab = tabId
    }

    public func markAccessed(tab tabId: UUID) {
        // Move to end of access order (most recently accessed)
        accessOrder.removeAll { $0 == tabId }
        accessOrder.append(tabId)
    }

    public func checkMemoryPressure() {
        var totalMemory = estimateMemory()

        if totalMemory <= appMemoryLimitBytes { return }

        // Shrink inactive tabs in LRU order (oldest first)
        for tabId in accessOrder {
            if tabId == activeTab { continue }
            guard var buffer = buffers[tabId] else { continue }

            if buffer.count > inactiveTabMinLines {
                let excess = buffer.count - inactiveTabMinLines
                buffer.removeFirst(excess)
                buffers[tabId] = buffer
            }

            totalMemory = estimateMemory()
            if totalMemory <= appMemoryLimitBytes { break }
        }
    }

    private func estimateMemory() -> Int {
        var total = 0
        for (_, buffer) in buffers {
            for line in buffer {
                total += line.utf8.count
            }
        }
        return total
    }
}
