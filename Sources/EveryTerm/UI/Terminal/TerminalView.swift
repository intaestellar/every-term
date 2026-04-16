import SwiftUI
import SwiftTerm

/// SwiftTerm wrapper for embedding a terminal emulator in SwiftUI
public struct TerminalView: NSViewRepresentable {
    private let connection: (any RemoteConnection)?

    public init(connection: (any RemoteConnection)? = nil) {
        self.connection = connection
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(connection: connection)
    }

    public func makeNSView(context: Context) -> SwiftTerm.LocalProcessTerminalView {
        let terminalView = SwiftTerm.LocalProcessTerminalView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        terminalView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)

        context.coordinator.terminalView = terminalView

        if let connection = connection {
            // Remote mode: pipe data through RemoteConnection
            context.coordinator.startRemoteSession(connection: connection, terminalView: terminalView)
        } else {
            // Local shell mode
            let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
            terminalView.startProcess(executable: shell, args: [], environment: nil, execName: "-" + (shell as NSString).lastPathComponent)
        }

        return terminalView
    }

    public func updateNSView(_ nsView: SwiftTerm.LocalProcessTerminalView, context: Context) {
        // Update terminal view if needed
    }

    @MainActor
    public class Coordinator: NSObject {
        var connection: (any RemoteConnection)?
        weak var terminalView: SwiftTerm.LocalProcessTerminalView?
        private var outputTask: Task<Void, Never>?
        private var connectTask: Task<Void, Never>?

        init(connection: (any RemoteConnection)?) {
            self.connection = connection
        }

        func startRemoteSession(connection: any RemoteConnection, terminalView: SwiftTerm.LocalProcessTerminalView) {
            let tv = terminalView
            connectTask = Task { @MainActor [weak self] in
                do {
                    try await connection.connect()
                } catch {
                    let errorMsg = "\r\n[Connection failed: \(error.localizedDescription)]\r\n"
                    if let data = errorMsg.data(using: .utf8) {
                        tv.feed(byteArray: ArraySlice(data))
                    }
                    return
                }

                let stream = await connection.outputStream
                self?.outputTask = Task { @MainActor in
                    for await data in stream {
                        tv.feed(byteArray: ArraySlice(data))
                    }
                }
            }
        }

        /// Send data from terminal to remote connection
        func sendToRemote(_ data: Data) {
            guard let connection = connection else { return }
            Task {
                try? await connection.send(data)
            }
        }

        deinit {
            outputTask?.cancel()
            connectTask?.cancel()
        }
    }
}
