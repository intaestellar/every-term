import SwiftUI

/// Session list sidebar with tree view, search, and context menus
public struct SessionListView: View {
    @Binding var selectedSessionId: UUID?
    @State private var searchText: String = ""
    @State private var showingEditor: Bool = false
    @State private var editingSession: Session?

    @ObservedObject var sessionStore: SessionStore
    let onConnect: (Session) -> Void

    public init(
        selectedSessionId: Binding<UUID?>,
        sessionStore: SessionStore,
        onConnect: @escaping (Session) -> Void
    ) {
        self._selectedSessionId = selectedSessionId
        self.sessionStore = sessionStore
        self.onConnect = onConnect
    }

    private var filteredSessions: [Session] {
        let sessions = sessionStore.allSessions
        if searchText.isEmpty { return sessions }
        return sessions.filter { session in
            session.name.localizedCaseInsensitiveContains(searchText)
            || session.host.localizedCaseInsensitiveContains(searchText)
            || session.username.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var recentSessions: [Session] {
        sessionStore.allSessions
            .filter { $0.lastConnectedAt != nil }
            .sorted { ($0.lastConnectedAt ?? .distantPast) > ($1.lastConnectedAt ?? .distantPast) }
            .prefix(5)
            .map { $0 }
    }

    private var rootGroups: [SessionGroup] {
        sessionStore.allGroups
            .filter { $0.parentId == nil }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var ungroupedSessions: [Session] {
        filteredSessions.filter { $0.groupId == nil }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search bar
            TextField("Search sessions...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(8)

            List(selection: $selectedSessionId) {
                // Recent sessions section
                if !recentSessions.isEmpty && searchText.isEmpty {
                    Section("Recent") {
                        ForEach(recentSessions, id: \.id) { session in
                            sessionRow(session)
                        }
                    }
                }

                // Groups tree
                if !rootGroups.isEmpty {
                    Section("Groups") {
                        ForEach(rootGroups, id: \.id) { group in
                            let groupSessions = filteredSessions.filter { $0.groupId == group.id }
                            let childGroups = sessionStore.allGroups
                                .filter { $0.parentId == group.id }
                                .sorted { $0.sortOrder < $1.sortOrder }

                            SessionGroupView(
                                group: group,
                                sessions: groupSessions,
                                childGroups: childGroups,
                                allGroups: sessionStore.allGroups,
                                allSessions: filteredSessions,
                                selectedSessionId: $selectedSessionId,
                                onConnect: onConnect,
                                onEdit: { session in
                                    editingSession = session
                                    showingEditor = true
                                },
                                onDelete: { session in deleteSession(session) },
                                onDuplicate: { session in duplicateSession(session) },
                                onEditGroup: { _ in },
                                onDeleteGroup: { group in deleteGroup(group) }
                            )
                        }
                    }
                }

                // Ungrouped sessions
                Section("Sessions") {
                    if ungroupedSessions.isEmpty && rootGroups.isEmpty {
                        Text("No sessions configured")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(ungroupedSessions, id: \.id) { session in
                            sessionRow(session)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    editingSession = nil
                    showingEditor = true
                }) {
                    Image(systemName: "plus")
                }
                .help("Add new session")
            }
        }
        .navigationTitle("Sessions")
        .sheet(isPresented: $showingEditor) {
            if let session = editingSession {
                SessionEditorView(session: session) { data in
                    updateSession(session, with: data)
                }
            } else {
                SessionEditorView { data in
                    createSession(from: data)
                }
            }
        }
    }

    @ViewBuilder
    private func sessionRow(_ session: Session) -> some View {
        HStack(spacing: 6) {
            Image(systemName: iconForSessionType(session.type))
                .foregroundStyle(Color.accentColor)
                .font(.caption)

            VStack(alignment: .leading, spacing: 1) {
                Text(session.name)
                    .font(.body)
                    .lineLimit(1)

                Text("\(session.username)@\(session.host)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .tag(session.id)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onConnect(session) }
        .contextMenu {
            Button("Connect") { onConnect(session) }
            Divider()
            Button("Edit...") {
                editingSession = session
                showingEditor = true
            }
            Button("Duplicate") { duplicateSession(session) }
            Divider()
            Button("Delete", role: .destructive) { deleteSession(session) }
        }
    }

    private func iconForSessionType(_ type: SessionType) -> String {
        switch type {
        case .ssh: return "terminal"
        case .local: return "desktopcomputer"
        case .rdp: return "display"
        case .vnc: return "eye"
        case .telnet: return "network"
        case .serial: return "cable.connector"
        }
    }

    // MARK: - Actions

    private func createSession(from data: SessionEditorView.SessionEditorData) {
        let session = Session(
            name: data.name,
            type: data.type,
            host: data.host,
            username: data.username,
            authMethod: data.authMethod,
            port: data.port,
            keyPath: data.keyPath,
            keepAliveInterval: data.keepAliveInterval,
            encoding: data.encoding,
            startupCommand: data.startupCommand,
            icon: data.icon,
            colorHex: data.colorHex
        )
        try? sessionStore.add(session)
        applyProtocolConfig(from: data, sessionId: session.id)
    }

    private func updateSession(_ session: Session, with data: SessionEditorView.SessionEditorData) {
        session.name = data.name
        session.type = data.type
        session.host = data.host
        session.port = data.port
        session.username = data.username
        session.authMethod = data.authMethod
        session.keyPath = data.keyPath
        session.keepAliveInterval = data.keepAliveInterval
        session.encoding = data.encoding
        session.startupCommand = data.startupCommand
        session.icon = data.icon
        session.colorHex = data.colorHex
        applyProtocolConfig(from: data, sessionId: session.id)
    }

    /// Persist protocol-specific payloads (RDP/VNC/Serial) into their
    /// respective SwiftData models keyed by `Session.id` in the store.
    private func applyProtocolConfig(
        from data: SessionEditorView.SessionEditorData,
        sessionId: UUID
    ) {
        if let rdp = data.rdp {
            let config = sessionStore.rdpConfig(forSessionId: sessionId)
                ?? RDPSessionConfig(sessionId: sessionId)
            config.gatewayHost = rdp.gatewayHost
            config.gatewayPort = rdp.gatewayPort
            sessionStore.setRDPConfig(config, forSessionId: sessionId)
        }
        if let vnc = data.vnc {
            let existing = sessionStore.vncConfig(forSessionId: sessionId)
            let config = existing ?? VNCSessionConfig(sessionId: sessionId)
            config.port = vnc.port
            config.scalingModeRaw = vnc.scalingMode.rawValue
            sessionStore.setVNCConfig(config, forSessionId: sessionId)
        }
        if let serial = data.serial {
            let existing = sessionStore.serialConfig(forSessionId: sessionId)
            let config = existing ?? SerialSessionConfig(sessionId: sessionId)
            config.devicePath = serial.devicePath
            config.baudRate = serial.baudRate
            config.parityRaw = serial.parity.rawValue
            sessionStore.setSerialConfig(config, forSessionId: sessionId)
        }
    }

    private func duplicateSession(_ session: Session) {
        let duplicate = Session(
            name: session.name + " (copy)",
            type: session.type,
            host: session.host,
            username: session.username,
            authMethod: session.authMethod,
            port: session.port,
            keyPath: session.keyPath,
            keepAliveInterval: session.keepAliveInterval,
            encoding: session.encoding,
            startupCommand: session.startupCommand,
            icon: session.icon,
            colorHex: session.colorHex,
            groupId: session.groupId
        )
        try? sessionStore.add(duplicate)
    }

    private func deleteSession(_ session: Session) {
        try? sessionStore.delete(session.id)
        if selectedSessionId == session.id {
            selectedSessionId = nil
        }
    }

    private func deleteGroup(_ group: SessionGroup) {
        try? sessionStore.deleteGroup(group.id)
    }
}
