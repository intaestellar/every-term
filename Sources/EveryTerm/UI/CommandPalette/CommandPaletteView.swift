import SwiftUI

/// Minimal command palette surface bound to ``CommandPaletteViewModel``.
///
/// The view is intentionally small — it renders a search field and the
/// filtered result list. The heavy lifting (fuzzy filter, selection state)
/// lives in the view-model so the UI stays trivially previewable.
@MainActor
public struct CommandPaletteView: View {
    @State private var query: String = ""
    private let viewModel: CommandPaletteViewModel
    private let onDismiss: (() -> Void)?

    public init(
        viewModel: CommandPaletteViewModel,
        onDismiss: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self._query = State(initialValue: viewModel.query)
    }

    public var body: some View {
        VStack(spacing: 0) {
            searchField

            Divider()

            resultList
        }
        .frame(minWidth: 480, minHeight: 320)
        .background(.regularMaterial)
        .cornerRadius(12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AccessibilityLabels.openCommandPaletteLabel)
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("세션 또는 명령 검색", text: Binding(
                get: { query },
                set: { newValue in
                    query = newValue
                    viewModel.query = newValue
                }
            ))
            .textFieldStyle(.plain)
            .font(.title3)
            .accessibilityLabel("검색")

            if !query.isEmpty {
                Button {
                    query = ""
                    viewModel.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("검색어 지우기")
            }
        }
        .padding(12)
    }

    private var resultList: some View {
        List {
            ForEach(Array(viewModel.filteredItems.enumerated()), id: \.element.id) { index, item in
                HStack(spacing: 10) {
                    Image(systemName: item.iconName)
                        .frame(width: 18)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                        if let subtitle = item.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if index == viewModel.selectedIndex {
                        Image(systemName: "return")
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .padding(.vertical, 2)
                .listRowBackground(
                    index == viewModel.selectedIndex
                        ? Color.accentColor.opacity(0.15)
                        : Color.clear
                )
                .onTapGesture {
                    viewModel.activateSelected()
                    onDismiss?()
                }
                .accessibilityLabel(item.title)
                .accessibilityHint(item.subtitle ?? "")
            }
        }
        .listStyle(.plain)
    }
}
