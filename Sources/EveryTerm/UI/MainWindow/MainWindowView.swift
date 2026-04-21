import SwiftUI

/// Main window layout with 3-column design: sidebar, tab bar + terminal, status bar
public struct MainWindowView: View {
    @StateObject private var tabManager = TabManager()
    @StateObject private var sessionStore = SessionStore()
    @State private var selectedSessionId: UUID?
    @State private var connectionState: ConnectionState = .disconnected
    @State private var showSFTPPanel: Bool = false
    @State private var sftpViewModel: SFTPBrowserViewModel?

    public init() {}

    public var body: some View {
        NavigationSplitView {
            SessionListView(
                selectedSessionId: $selectedSessionId,
                sessionStore: sessionStore,
                onConnect: { session in connectToSession(session) }
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
        } detail: {
            HSplitView {
                VStack(spacing: 0) {
                    TabBarView(tabManager: tabManager)

                    // Insecure-protocol warning (e.g., Telnet) rendered above the
                    // active tab's content surface. Hidden automatically for
                    // encrypted protocols via `SecurityWarningBanner.isInsecure`.
                    if let type = activeSessionType {
                        SecurityWarningBanner(sessionType: type)
                    }

                    // Active tab content: route by SessionType.
                    activeContentView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Status bar
                    HStack {
                        ConnectionStatusView(state: connectionState)
                        Spacer()

                        Button(action: { showSFTPPanel.toggle() }) {
                            Image(systemName: "folder.badge.gearshape")
                        }
                        .buttonStyle(.borderless)
                        .help("Toggle SFTP Panel")

                        Text("UTF-8")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("80x24")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.bar)
                }

                // SFTP sidebar panel
                if showSFTPPanel, let vm = sftpViewModel {
                    SFTPBrowserView(viewModel: vm)
                        .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
                }
            }
        }
    }

    /// Session corresponding to the currently active tab, if any.
    private var activeSession: Session? {
        guard let activeId = tabManager.activeTabId,
              let tab = tabManager.tabs.first(where: { $0.id == activeId }),
              let sessionId = tab.sessionId else { return nil }
        return sessionStore.session(byId: sessionId)
    }

    /// SessionType of the currently active tab, used to drive the warning
    /// banner and content routing. Returns `nil` when no tab is selected or
    /// the tab has no associated session (fresh/unassigned tabs).
    private var activeSessionType: SessionType? {
        activeSession?.type
    }

    /// Route the active tab to the appropriate content view based on its
    /// `SessionType`. RDP/VNC render their dedicated placeholder views;
    /// SSH/Local/Telnet/Serial share `SplitTerminalView`.
    @ViewBuilder
    private var activeContentView: some View {
        if let type = activeSessionType {
            switch TabManager.contentRoute(for: type) {
            case .terminal:
                SplitTerminalView()
            case .rdp:
                RDPView(host: activeSession?.host ?? "")
            case .vnc:
                VNCView(host: activeSession?.host ?? "")
            }
        } else {
            SplitTerminalView()
        }
    }

    private func connectToSession(_ session: Session) {
        let tab = TabItem(
            title: session.name,
            sessionId: session.id
        )
        tabManager.addTab(tab)
        session.lastConnectedAt = Date()

        // Initialize SFTP ViewModel for SSH sessions
        if session.type == .ssh {
            let sshAdapter = SSHAdapter(
                host: session.host,
                port: session.port,
                username: session.username,
                authMethod: session.authMethod == .key
                    ? .key(path: session.keyPath ?? "~/.ssh/id_ed25519", passphrase: nil)
                    : .password(SecureBytes([])),
                keepAliveInterval: session.keepAliveInterval
            )
            let sftpConnection = CitadelSFTPAdapter(sshAdapter: sshAdapter)
            sftpViewModel = SFTPBrowserViewModel(connection: sftpConnection)
        }
    }
}
