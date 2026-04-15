import SwiftUI

/// SFTP browser panel root view — file list, path bar, and toolbar.
public struct SFTPBrowserView: View {
    @StateObject private var viewModel: SFTPBrowserViewModel

    public init(viewModel: SFTPBrowserViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbar

            Divider()

            // Path bar
            pathBar

            Divider()

            // File list
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await viewModel.refresh() }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                SFTPFileListView(
                    files: viewModel.sortedFiles,
                    onNavigate: { entry in
                        Task { await viewModel.navigateTo(path: entry.path) }
                    },
                    onOpen: nil
                )
            }
        }
        .task {
            await viewModel.navigateTo(path: viewModel.currentPath)
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 4) {
            Button(action: { Task { await viewModel.navigateUp() } }) {
                Image(systemName: "arrow.up")
            }
            .buttonStyle(.borderless)
            .help("Parent Directory")

            Button(action: { Task { await viewModel.navigateHome() } }) {
                Image(systemName: "house")
            }
            .buttonStyle(.borderless)
            .help("Home Directory")

            Button(action: { Task { await viewModel.refresh() } }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("Refresh")

            Spacer()

            Toggle(isOn: $viewModel.showHiddenFiles) {
                Image(systemName: "eye")
            }
            .toggleStyle(.button)
            .buttonStyle(.borderless)
            .help("Show Hidden Files")

            sortMenu
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private var sortMenu: some View {
        Menu {
            Button("Name") { viewModel.sortBy = .name }
            Button("Size") { viewModel.sortBy = .size }
            Button("Date") { viewModel.sortBy = .date }
            Button("Type") { viewModel.sortBy = .type }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .menuStyle(.borderlessButton)
        .frame(width: 24)
        .help("Sort By")
    }

    // MARK: - Path Bar

    private var pathBar: some View {
        HStack(spacing: 4) {
            Image(systemName: "folder")
                .foregroundStyle(.secondary)

            TextField("Path", text: $viewModel.currentPath)
                .textFieldStyle(.plain)
                .font(.system(.caption, design: .monospaced))
                .onSubmit {
                    Task { await viewModel.navigateTo(path: viewModel.currentPath) }
                }

            if !viewModel.searchQuery.isEmpty {
                Button(action: { viewModel.searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}
