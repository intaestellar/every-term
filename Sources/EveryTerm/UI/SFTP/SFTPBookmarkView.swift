import SwiftUI
import SwiftData

/// View for managing SFTP bookmarks — add, remove, and navigate to bookmarked paths.
public struct SFTPBookmarkView: View {
    @Query(sort: \SFTPBookmark.createdAt, order: .reverse) private var bookmarks: [SFTPBookmark]
    @Environment(\.modelContext) private var modelContext

    public let sessionId: UUID
    public var onNavigate: ((String) -> Void)?

    public init(sessionId: UUID, onNavigate: ((String) -> Void)? = nil) {
        self.sessionId = sessionId
        self.onNavigate = onNavigate
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Bookmarks")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Divider()

            let filtered = bookmarks.filter { $0.sessionId == sessionId }

            if filtered.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bookmark")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No bookmarks yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filtered, id: \.id) { bookmark in
                        HStack {
                            Image(systemName: "bookmark.fill")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading) {
                                Text(bookmark.name)
                                    .lineLimit(1)
                                Text(bookmark.path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.head)
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onNavigate?(bookmark.path)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(filtered[index])
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    /// Adds a bookmark for the given path.
    public func addBookmark(path: String, name: String? = nil) {
        let bookmarkName = name ?? (path as NSString).lastPathComponent
        let bookmark = SFTPBookmark(
            id: UUID(),
            sessionId: sessionId,
            path: path,
            name: bookmarkName,
            createdAt: Date()
        )
        modelContext.insert(bookmark)
    }
}
