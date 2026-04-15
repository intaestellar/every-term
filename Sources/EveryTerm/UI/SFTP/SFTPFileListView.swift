import SwiftUI

/// Renders SFTP file entries as a list with icon, name, size, date, and permissions columns.
public struct SFTPFileListView: View {
    public let files: [SFTPFileEntry]
    public var onNavigate: ((SFTPFileEntry) -> Void)?
    public var onOpen: ((SFTPFileEntry) -> Void)?

    public init(
        files: [SFTPFileEntry],
        onNavigate: ((SFTPFileEntry) -> Void)? = nil,
        onOpen: ((SFTPFileEntry) -> Void)? = nil
    ) {
        self.files = files
        self.onNavigate = onNavigate
        self.onOpen = onOpen
    }

    public var body: some View {
        List(files) { entry in
            HStack(spacing: 8) {
                // Icon
                Image(systemName: iconName(for: entry))
                    .foregroundStyle(entry.isDirectory ? .blue : .secondary)
                    .frame(width: 20)

                // Name
                Text(entry.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Size
                Text(entry.isDirectory ? "--" : formattedSize(entry.size))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 70, alignment: .trailing)

                // Date
                Text(formattedDate(entry.modifiedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .trailing)

                // Permissions
                Text(formattedPermissions(entry.permissions))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 80, alignment: .trailing)
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                if entry.isDirectory {
                    onNavigate?(entry)
                } else {
                    onOpen?(entry)
                }
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Formatting

    private func iconName(for entry: SFTPFileEntry) -> String {
        if entry.isSymlink {
            return "link"
        } else if entry.isDirectory {
            return "folder.fill"
        } else {
            return "doc.fill"
        }
    }

    private func formattedSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formattedPermissions(_ perms: UInt32) -> String {
        let filePerms = perms & 0o777
        var result = ""
        let chars: [(UInt32, String)] = [
            (0o400, "r"), (0o200, "w"), (0o100, "x"),
            (0o040, "r"), (0o020, "w"), (0o010, "x"),
            (0o004, "r"), (0o002, "w"), (0o001, "x"),
        ]
        for (mask, char) in chars {
            result += (filePerms & mask) != 0 ? char : "-"
        }
        return result
    }
}
