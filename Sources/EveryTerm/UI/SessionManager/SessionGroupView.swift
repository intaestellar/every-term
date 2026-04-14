import SwiftUI

/// Folder view for session groups in the sidebar tree
public struct SessionGroupView: View {
    let group: SessionGroup
    let sessions: [Session]
    let childGroups: [SessionGroup]
    let allGroups: [SessionGroup]
    let allSessions: [Session]
    @Binding var selectedSessionId: UUID?
    let onConnect: (Session) -> Void
    let onEdit: (Session) -> Void
    let onDelete: (Session) -> Void
    let onDuplicate: (Session) -> Void
    let onEditGroup: (SessionGroup) -> Void
    let onDeleteGroup: (SessionGroup) -> Void

    public init(
        group: SessionGroup,
        sessions: [Session],
        childGroups: [SessionGroup],
        allGroups: [SessionGroup],
        allSessions: [Session],
        selectedSessionId: Binding<UUID?>,
        onConnect: @escaping (Session) -> Void,
        onEdit: @escaping (Session) -> Void,
        onDelete: @escaping (Session) -> Void,
        onDuplicate: @escaping (Session) -> Void,
        onEditGroup: @escaping (SessionGroup) -> Void,
        onDeleteGroup: @escaping (SessionGroup) -> Void
    ) {
        self.group = group
        self.sessions = sessions
        self.childGroups = childGroups
        self.allGroups = allGroups
        self.allSessions = allSessions
        self._selectedSessionId = selectedSessionId
        self.onConnect = onConnect
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onDuplicate = onDuplicate
        self.onEditGroup = onEditGroup
        self.onDeleteGroup = onDeleteGroup
    }

    public var body: some View {
        DisclosureGroup(
            isExpanded: .constant(group.isExpanded),
            content: {
                // Child groups
                ForEach(childGroups, id: \.id) { childGroup in
                    let childSessions = allSessions.filter { $0.groupId == childGroup.id }
                    let grandchildGroups = allGroups.filter { $0.parentId == childGroup.id }
                        .sorted(by: { $0.sortOrder < $1.sortOrder })

                    SessionGroupView(
                        group: childGroup,
                        sessions: childSessions,
                        childGroups: grandchildGroups,
                        allGroups: allGroups,
                        allSessions: allSessions,
                        selectedSessionId: $selectedSessionId,
                        onConnect: onConnect,
                        onEdit: onEdit,
                        onDelete: onDelete,
                        onDuplicate: onDuplicate,
                        onEditGroup: onEditGroup,
                        onDeleteGroup: onDeleteGroup
                    )
                }

                // Sessions in this group
                ForEach(sessions, id: \.id) { session in
                    SessionRowView(
                        session: session,
                        isSelected: selectedSessionId == session.id,
                        onSelect: { selectedSessionId = session.id },
                        onConnect: { onConnect(session) }
                    )
                    .contextMenu {
                        Button("Connect") { onConnect(session) }
                        Divider()
                        Button("Edit...") { onEdit(session) }
                        Button("Duplicate") { onDuplicate(session) }
                        Divider()
                        Button("Delete", role: .destructive) { onDelete(session) }
                    }
                }
            },
            label: {
                Label {
                    Text(group.name)
                        .font(.body)
                } icon: {
                    Image(systemName: group.icon ?? "folder")
                        .foregroundStyle(.secondary)
                }
            }
        )
        .contextMenu {
            Button("Edit Group...") { onEditGroup(group) }
            Divider()
            Button("Delete Group", role: .destructive) { onDeleteGroup(group) }
        }
    }
}

/// Row view for a single session in the sidebar
struct SessionRowView: View {
    let session: Session
    let isSelected: Bool
    let onSelect: () -> Void
    let onConnect: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconForSessionType(session.type))
                .foregroundStyle(colorForSession(session))
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
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onTapGesture(count: 2, perform: onConnect)
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

    private func colorForSession(_ session: Session) -> Color {
        if let hex = session.colorHex {
            return Color(hex: hex)
        }
        return .accentColor
    }
}

// MARK: - Color extension for hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}
