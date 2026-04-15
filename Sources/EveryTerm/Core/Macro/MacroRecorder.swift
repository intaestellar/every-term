import Foundation

public actor MacroRecorder {
    public private(set) var isRecording: Bool = false
    private var actions: [MacroAction] = []
    private var lastEventTime: Date?
    private var pendingText: String = ""

    private let waitThreshold: TimeInterval = 0.5

    public init() {}

    public func startRecording() {
        isRecording = true
        actions = []
        lastEventTime = nil
        pendingText = ""
    }

    public func stopRecording() -> [MacroAction] {
        // Flush pending text
        flushPendingText()
        isRecording = false
        let result = actions
        actions = []
        lastEventTime = nil
        pendingText = ""
        return result
    }

    public func recordTextInput(_ text: String) {
        let now = Date()
        insertWaitIfNeeded(now)

        pendingText += text
        lastEventTime = now
    }

    public func recordKeyPress(key: String, modifiers: [String]) {
        let now = Date()
        insertWaitIfNeeded(now)

        // Flush pending text before key press
        flushPendingText()

        actions.append(.keyPress(key: key, modifiers: modifiers))
        lastEventTime = now
    }

    private func insertWaitIfNeeded(_ now: Date) {
        guard let last = lastEventTime else { return }
        let interval = now.timeIntervalSince(last)
        if interval >= waitThreshold {
            // Flush pending text before wait
            flushPendingText()
            actions.append(.wait(seconds: interval))
        }
    }

    private func flushPendingText() {
        if !pendingText.isEmpty {
            actions.append(.type(text: pendingText))
            pendingText = ""
        }
    }
}
