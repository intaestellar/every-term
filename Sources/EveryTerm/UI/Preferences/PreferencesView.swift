import SwiftUI

/// Settings view with tabs for General, Terminal, SSH, Shortcuts, and Advanced
public struct PreferencesView: View {
    public init() {}

    public var body: some View {
        TabView {
            GeneralPreferencesView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            TerminalPreferencesView()
                .tabItem {
                    Label("Terminal", systemImage: "terminal")
                }

            SSHPreferencesView()
                .tabItem {
                    Label("SSH", systemImage: "lock.shield")
                }

            ShortcutsPreferencesView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }

            AdvancedPreferencesView()
                .tabItem {
                    Label("Advanced", systemImage: "wrench.and.screwdriver")
                }
        }
        .frame(width: 500, height: 400)
    }
}

struct GeneralPreferencesView: View {
    @AppStorage("startupBehavior") private var startupBehavior = "emptyTab"

    var body: some View {
        Form {
            Picker("On startup:", selection: $startupBehavior) {
                Text("Open empty tab").tag("emptyTab")
                Text("Restore last sessions").tag("restoreLast")
            }
        }
        .padding()
    }
}

struct TerminalPreferencesView: View {
    @AppStorage("terminalTheme") private var selectedTheme = "Default"
    @AppStorage("cursorStyle") private var cursorStyle = "block"
    @AppStorage("scrollbackLines") private var scrollbackLines = 10000

    var body: some View {
        Form {
            Picker("Theme:", selection: $selectedTheme) {
                ForEach(TerminalTheme.builtInThemes, id: \.name) { theme in
                    Text(theme.name).tag(theme.name)
                }
            }

            Picker("Cursor style:", selection: $cursorStyle) {
                Text("Block").tag("block")
                Text("Underline").tag("underline")
                Text("Bar").tag("bar")
            }

            TextField("Scrollback lines:", value: $scrollbackLines, format: .number)
        }
        .padding()
    }
}

struct SSHPreferencesView: View {
    @AppStorage("defaultSSHPort") private var defaultPort = 22
    @AppStorage("keepAliveInterval") private var keepAliveInterval = 60
    @AppStorage("defaultAuthMethod") private var defaultAuthMethod = "password"

    var body: some View {
        Form {
            TextField("Default port:", value: $defaultPort, format: .number)
            TextField("Keep-alive interval (sec):", value: $keepAliveInterval, format: .number)
            Picker("Default auth method:", selection: $defaultAuthMethod) {
                Text("Password").tag("password")
                Text("SSH Key").tag("key")
                Text("Agent").tag("agent")
            }
        }
        .padding()
    }
}

struct ShortcutsPreferencesView: View {
    var body: some View {
        Form {
            Text("Keyboard shortcuts customization")
                .foregroundStyle(.secondary)
            GroupBox("Terminal") {
                LabeledContent("New Tab", value: "Cmd+T")
                LabeledContent("Close Tab", value: "Cmd+W")
                LabeledContent("Split Vertical", value: "Cmd+D")
                LabeledContent("Split Horizontal", value: "Cmd+Shift+D")
                LabeledContent("Toggle Sidebar", value: "Cmd+Shift+S")
            }
        }
        .padding()
    }
}

struct AdvancedPreferencesView: View {
    @AppStorage("logLevel") private var logLevel = "info"

    var body: some View {
        Form {
            Picker("Log level:", selection: $logLevel) {
                Text("Debug").tag("debug")
                Text("Info").tag("info")
                Text("Warning").tag("warning")
                Text("Error").tag("error")
            }

            LabeledContent("Log file:") {
                Text("~/Library/Logs/EveryTerm/")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
