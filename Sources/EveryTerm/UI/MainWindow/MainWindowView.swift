import SwiftUI

/// Main window layout with 3-column design: sidebar, tab bar + terminal, status bar
public struct MainWindowView: View {
    @StateObject private var tabManager = TabManager()
    @StateObject private var sessionStore = SessionStore()
    @State private var selectedSessionId: UUID?
    @State private var connectionState: ConnectionState = .disconnected

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
            VStack(spacing: 0) {
                TabBarView(tabManager: tabManager)

                // Terminal area
                SplitTerminalView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Status bar
                HStack {
                    ConnectionStatusView(state: connectionState)
                    Spacer()
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
        }
    }

    private func connectToSession(_ session: Session) {
        let tab = TabItem(
            title: session.name,
            sessionId: session.id
        )
        tabManager.addTab(tab)
        session.lastConnectedAt = Date()
    }
}
