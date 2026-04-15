import Foundation

public enum MacroPlayerError: Error, Sendable {
    case waitForOutputTimeout(pattern: String)
    case cancelled
}

public actor MacroPlayer {
    public private(set) var isPlaying: Bool = false
    private var isStopped: Bool = false
    private var isPaused: Bool = false

    public init() {}

    public func play(actions: [MacroAction], on connection: any RemoteConnection) async throws {
        isPlaying = true
        isStopped = false
        isPaused = false

        defer { isPlaying = false }

        for action in actions {
            if isStopped { break }

            // Wait while paused
            while isPaused && !isStopped {
                try await Task.sleep(for: .milliseconds(10))
            }
            if isStopped { break }

            switch action {
            case .type(let text):
                try await connection.send(Data(text.utf8))

            case .keyPress(let key, _):
                let keyCode = convertKeyToCode(key)
                try await connection.send(Data(keyCode.utf8))

            case .wait(let seconds):
                // Use a single sleep with periodic stop/pause checks
                let deadline = ContinuousClock.now + .milliseconds(Int(seconds * 1000))
                while ContinuousClock.now < deadline {
                    if isStopped { return }
                    while isPaused && !isStopped {
                        try await Task.sleep(for: .milliseconds(10))
                    }
                    if isStopped { return }
                    let remaining = deadline - ContinuousClock.now
                    if remaining <= .zero { break }
                    let sleepDuration = min(remaining, .milliseconds(50))
                    try await Task.sleep(for: sleepDuration)
                }

            case .waitForOutput(let pattern, let timeout):
                try await waitForOutput(pattern: pattern, timeout: timeout, on: connection)
            }
        }
    }

    public func stop() {
        isStopped = true
        isPaused = false
    }

    public func pause() {
        isPaused = true
    }

    public func resume() {
        isPaused = false
    }

    private func waitForOutput(pattern: String, timeout: Double, on connection: any RemoteConnection) async throws {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            throw MacroPlayerError.waitForOutputTimeout(pattern: pattern)
        }

        let stream = await connection.outputStream
        let deadline = ContinuousClock.now + .seconds(timeout)

        // Use a task to consume output and check pattern
        let matched = try await withThrowingTaskGroup(of: Bool.self) { group in
            group.addTask {
                for await data in stream {
                    if let text = String(data: data, encoding: .utf8) {
                        let range = NSRange(text.startIndex..., in: text)
                        if regex.firstMatch(in: text, range: range) != nil {
                            return true
                        }
                    }
                }
                return false
            }

            group.addTask {
                let remaining = deadline - ContinuousClock.now
                if remaining > .zero {
                    try await Task.sleep(for: remaining)
                }
                return false
            }

            // First task to complete wins
            if let result = try await group.next() {
                group.cancelAll()
                return result
            }
            return false
        }

        if !matched {
            throw MacroPlayerError.waitForOutputTimeout(pattern: pattern)
        }
    }

    private func convertKeyToCode(_ key: String) -> String {
        switch key {
        case "Return": return "\r"
        case "Tab": return "\t"
        case "Escape": return "\u{1B}"
        case "Backspace", "Delete": return "\u{7F}"
        case "Up": return "\u{1B}[A"
        case "Down": return "\u{1B}[B"
        case "Right": return "\u{1B}[C"
        case "Left": return "\u{1B}[D"
        default: return key
        }
    }
}
