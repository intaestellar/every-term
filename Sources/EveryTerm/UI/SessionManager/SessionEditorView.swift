import SwiftUI

/// Session editor/creation form presented as a sheet
public struct SessionEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var sessionType: SessionType
    @State private var host: String
    @State private var port: String
    @State private var username: String
    @State private var authMethod: AuthMethod
    @State private var keyPath: String
    @State private var keepAliveInterval: String
    @State private var encoding: String
    @State private var startupCommand: String
    @State private var icon: String
    @State private var colorHex: String

    private let existingSession: Session?
    private let onSave: (SessionEditorData) -> Void

    /// Data structure for passing editor form values
    public struct SessionEditorData: Sendable {
        public let name: String
        public let type: SessionType
        public let host: String
        public let port: Int
        public let username: String
        public let authMethod: AuthMethod
        public let keyPath: String?
        public let keepAliveInterval: Int
        public let encoding: String
        public let startupCommand: String?
        public let icon: String?
        public let colorHex: String?
    }

    /// Create a new session
    public init(onSave: @escaping (SessionEditorData) -> Void) {
        self.existingSession = nil
        self.onSave = onSave
        self._name = State(initialValue: "")
        self._sessionType = State(initialValue: .ssh)
        self._host = State(initialValue: "")
        self._port = State(initialValue: "22")
        self._username = State(initialValue: "root")
        self._authMethod = State(initialValue: .password)
        self._keyPath = State(initialValue: "")
        self._keepAliveInterval = State(initialValue: "60")
        self._encoding = State(initialValue: "UTF-8")
        self._startupCommand = State(initialValue: "")
        self._icon = State(initialValue: "")
        self._colorHex = State(initialValue: "")
    }

    /// Edit an existing session
    public init(session: Session, onSave: @escaping (SessionEditorData) -> Void) {
        self.existingSession = session
        self.onSave = onSave
        self._name = State(initialValue: session.name)
        self._sessionType = State(initialValue: session.type)
        self._host = State(initialValue: session.host)
        self._port = State(initialValue: String(session.port))
        self._username = State(initialValue: session.username)
        self._authMethod = State(initialValue: session.authMethod)
        self._keyPath = State(initialValue: session.keyPath ?? "")
        self._keepAliveInterval = State(initialValue: String(session.keepAliveInterval))
        self._encoding = State(initialValue: session.encoding)
        self._startupCommand = State(initialValue: session.startupCommand ?? "")
        self._icon = State(initialValue: session.icon ?? "")
        self._colorHex = State(initialValue: session.colorHex ?? "")
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text(existingSession != nil ? "Edit Session" : "New Session")
                    .font(.headline)
                Spacer()
            }
            .padding()

            Form {
                // Basic settings
                Section("General") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $sessionType) {
                        ForEach(SessionType.allCases, id: \.self) { type in
                            Text(type.rawValue.uppercased()).tag(type)
                        }
                    }
                    TextField("Icon (SF Symbol name)", text: $icon)
                    TextField("Color (hex)", text: $colorHex)
                }

                // Connection settings
                Section("Connection") {
                    TextField("Host", text: $host)
                    TextField("Port", text: $port)
                    TextField("Username", text: $username)
                }

                // Authentication
                Section("Authentication") {
                    Picker("Method", selection: $authMethod) {
                        ForEach(AuthMethod.allCases, id: \.self) { method in
                            Text(method.rawValue.capitalized).tag(method)
                        }
                    }

                    if authMethod == .key {
                        HStack {
                            TextField("Key Path", text: $keyPath)
                            Button("Browse...") {
                                browseForKeyFile()
                            }
                        }
                    }
                }

                // Advanced settings
                Section("Advanced") {
                    TextField("Keep-Alive Interval (seconds)", text: $keepAliveInterval)
                    Picker("Encoding", selection: $encoding) {
                        Text("UTF-8").tag("UTF-8")
                        Text("ASCII").tag("ASCII")
                        Text("ISO-8859-1").tag("ISO-8859-1")
                        Text("EUC-KR").tag("EUC-KR")
                        Text("Shift_JIS").tag("Shift_JIS")
                    }
                    TextField("Startup Command", text: $startupCommand)
                }
            }
            .formStyle(.grouped)

            // Action buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(existingSession != nil ? "Save" : "Create") {
                    saveSession()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || host.isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 450, idealWidth: 500, minHeight: 500, idealHeight: 600)
    }

    private func saveSession() {
        let data = SessionEditorData(
            name: name,
            type: sessionType,
            host: host,
            port: Int(port) ?? 22,
            username: username,
            authMethod: authMethod,
            keyPath: keyPath.isEmpty ? nil : keyPath,
            keepAliveInterval: Int(keepAliveInterval) ?? 60,
            encoding: encoding,
            startupCommand: startupCommand.isEmpty ? nil : startupCommand,
            icon: icon.isEmpty ? nil : icon,
            colorHex: colorHex.isEmpty ? nil : colorHex
        )
        onSave(data)
        dismiss()
    }

    private func browseForKeyFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: NSHomeDirectory() + "/.ssh")
        panel.message = "Select SSH Key File"

        if panel.runModal() == .OK, let url = panel.url {
            keyPath = url.path
        }
    }
}
