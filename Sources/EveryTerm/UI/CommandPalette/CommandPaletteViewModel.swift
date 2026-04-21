import Foundation

@MainActor
public final class CommandPaletteViewModel {
    public enum MoveDirection {
        case up
        case down
    }

    public var isVisible: Bool = false
    public private(set) var items: [CommandPaletteItem]
    public var query: String = "" {
        didSet {
            recomputeFiltered()
            selectedIndex = 0
        }
    }
    public private(set) var filteredItems: [CommandPaletteItem]
    public private(set) var selectedIndex: Int = 0

    private let filter: CommandPaletteFuzzyFilter
    private let onActivate: ((CommandPaletteItem) -> Void)?

    public init(
        items: [CommandPaletteItem],
        filter: CommandPaletteFuzzyFilter = CommandPaletteFuzzyFilter(),
        onActivate: ((CommandPaletteItem) -> Void)? = nil
    ) {
        self.items = items
        self.filter = filter
        self.onActivate = onActivate
        self.filteredItems = items
    }

    public func moveSelection(_ direction: MoveDirection) {
        guard filteredItems.isEmpty == false else {
            selectedIndex = 0
            return
        }
        switch direction {
        case .down:
            selectedIndex = min(selectedIndex + 1, filteredItems.count - 1)
        case .up:
            selectedIndex = max(selectedIndex - 1, 0)
        }
    }

    public func activateSelected() {
        defer { isVisible = false }
        guard filteredItems.indices.contains(selectedIndex) else { return }
        onActivate?(filteredItems[selectedIndex])
    }

    /// Activate the item at a specific index (e.g. from a mouse click).
    public func activateItem(at index: Int) {
        guard filteredItems.indices.contains(index) else { return }
        selectedIndex = index
        activateSelected()
    }

    public func reset() {
        query = ""
        selectedIndex = 0
        isVisible = false
    }

    public func setItems(_ newItems: [CommandPaletteItem]) {
        items = newItems
        // Recompute uses the same single path as `query.didSet`.
        recomputeFiltered()
        selectedIndex = 0
    }

    /// Single recomputation path — called from both `query.didSet` and
    /// `setItems(_:)` to keep filtered results in sync.
    private func recomputeFiltered() {
        filteredItems = filter.filter(items: items, query: query)
    }
}
