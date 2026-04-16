import Foundation

/// Sort criteria for file listings.
public enum SFTPSortBy: Sendable {
    case name
    case size
    case date
    case type
}

/// ViewModel for the SFTP browser sidebar.
@MainActor
public final class SFTPBrowserViewModel: ObservableObject {
    @Published public var currentPath: String = "~"
    @Published public var files: [SFTPFileEntry] = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var sortBy: SFTPSortBy = .name
    @Published public var showHiddenFiles: Bool = true
    @Published public var searchQuery: String = ""

    private let connection: any SFTPConnection
    private let cache: SFTPDirectoryCache?

    public init(connection: any SFTPConnection, cache: SFTPDirectoryCache? = nil) {
        self.connection = connection
        self.cache = cache
    }

    public func navigateTo(path: String) async {
        isLoading = true
        errorMessage = nil
        let previousPath = currentPath

        do {
            // Check cache first
            if let cache = cache, let cached = await cache.get(path) {
                currentPath = path
                files = cached
                isLoading = false
                return
            }

            let entries = try await connection.listDirectory(path)
            currentPath = path
            files = entries

            // Store in cache
            if let cache = cache {
                await cache.set(entries, for: path)
            }
        } catch {
            errorMessage = error.localizedDescription
            currentPath = previousPath
            files = []
        }

        isLoading = false
    }

    public func navigateUp() async {
        let parent = (currentPath as NSString).deletingLastPathComponent
        await navigateTo(path: parent)
    }

    public func navigateHome() async {
        await navigateTo(path: "~")
    }

    public func refresh() async {
        if let cache = cache {
            await cache.invalidate(path: currentPath)
        }
        await navigateTo(path: currentPath)
    }

    /// Files filtered by hidden-file toggle and search query.
    public var filteredFiles: [SFTPFileEntry] {
        var result = files

        if !showHiddenFiles {
            result = result.filter { !$0.name.hasPrefix(".") }
        }

        if !searchQuery.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }

        return result
    }

    /// Sorted files — directories always come first.
    public var sortedFiles: [SFTPFileEntry] {
        let filtered = filteredFiles

        let dirs = filtered.filter { $0.isDirectory }
        let nonDirs = filtered.filter { !$0.isDirectory }

        let sortedDirs: [SFTPFileEntry]
        let sortedNonDirs: [SFTPFileEntry]

        switch sortBy {
        case .name:
            sortedDirs = dirs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            sortedNonDirs = nonDirs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .size:
            sortedDirs = dirs.sorted { $0.size < $1.size }
            sortedNonDirs = nonDirs.sorted { $0.size < $1.size }
        case .date:
            sortedDirs = dirs.sorted { $0.modifiedAt < $1.modifiedAt }
            sortedNonDirs = nonDirs.sorted { $0.modifiedAt < $1.modifiedAt }
        case .type:
            sortedDirs = dirs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            sortedNonDirs = nonDirs.sorted {
                let ext0 = ($0.name as NSString).pathExtension
                let ext1 = ($1.name as NSString).pathExtension
                return ext0.localizedCaseInsensitiveCompare(ext1) == .orderedAscending
            }
        }

        return sortedDirs + sortedNonDirs
    }
}
