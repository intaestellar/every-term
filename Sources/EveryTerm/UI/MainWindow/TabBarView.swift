import SwiftUI

/// Custom tab bar with connection status icons and drag-and-drop reordering
public struct TabBarView: View {
    @ObservedObject var tabManager: TabManager

    public init(tabManager: TabManager) {
        self.tabManager = tabManager
    }

    public var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 1) {
                    ForEach(tabManager.tabs) { tab in
                        TabBarItemView(
                            tab: tab,
                            isActive: tab.id == tabManager.activeTabId,
                            onSelect: { tabManager.setActiveTab(tab.id) },
                            onClose: { tabManager.removeTab(tab.id) }
                        )
                    }
                }
            }

            Spacer()

            Button(action: addNewTab) {
                Image(systemName: "plus")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 8)
            .keyboardShortcut("t", modifiers: .command)
        }
        .frame(height: 30)
        .background(.bar)
        .background(
            // Cmd+W: close active tab
            Button("") { tabManager.closeActiveTab() }
                .keyboardShortcut("w", modifiers: .command)
                .hidden()
        )
        .background(
            // Cmd+Shift+[: previous tab
            Button("") { tabManager.selectPreviousTab() }
                .keyboardShortcut("[", modifiers: [.command, .shift])
                .hidden()
        )
        .background(
            // Cmd+Shift+]: next tab
            Button("") { tabManager.selectNextTab() }
                .keyboardShortcut("]", modifiers: [.command, .shift])
                .hidden()
        )
        .background(tabNumberShortcuts)
    }

    private func addNewTab() {
        let tab = TabItem(title: "Local Shell")
        tabManager.addTab(tab)
    }

    /// Cmd+1 through Cmd+9 tab switching
    @ViewBuilder
    private var tabNumberShortcuts: some View {
        Group {
            Button("") { tabManager.selectTab(at: 1) }
                .keyboardShortcut("1", modifiers: .command)
                .hidden()
            Button("") { tabManager.selectTab(at: 2) }
                .keyboardShortcut("2", modifiers: .command)
                .hidden()
            Button("") { tabManager.selectTab(at: 3) }
                .keyboardShortcut("3", modifiers: .command)
                .hidden()
            Button("") { tabManager.selectTab(at: 4) }
                .keyboardShortcut("4", modifiers: .command)
                .hidden()
            Button("") { tabManager.selectTab(at: 5) }
                .keyboardShortcut("5", modifiers: .command)
                .hidden()
            Button("") { tabManager.selectTab(at: 6) }
                .keyboardShortcut("6", modifiers: .command)
                .hidden()
            Button("") { tabManager.selectTab(at: 7) }
                .keyboardShortcut("7", modifiers: .command)
                .hidden()
            Button("") { tabManager.selectTab(at: 8) }
                .keyboardShortcut("8", modifiers: .command)
                .hidden()
            Button("") { tabManager.selectTab(at: 9) }
                .keyboardShortcut("9", modifiers: .command)
                .hidden()
        }
    }
}

struct TabBarItemView: View {
    let tab: TabItem
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)

            Text(tab.title)
                .font(.caption)
                .lineLimit(1)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 8))
            }
            .buttonStyle(.borderless)
            .opacity(isActive ? 1 : 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isActive ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(4)
        .onTapGesture(perform: onSelect)
    }

    private var statusColor: Color {
        if tab.connectionId != nil {
            return .green
        }
        return .gray
    }
}
