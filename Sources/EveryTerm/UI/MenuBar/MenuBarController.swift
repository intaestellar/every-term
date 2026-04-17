import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// Thin wrapper around `NSStatusItem` that renders the EveryTerm menu bar
/// entry. All state derives from an injected ``MenuBarViewModel`` so business
/// logic stays testable on non-UI targets.
///
/// On non-AppKit platforms (e.g. Linux CI) the controller compiles to a no-op
/// shell to keep the package cross-platform.
@MainActor
public final class MenuBarController {
    public let viewModel: MenuBarViewModel

    #if canImport(AppKit)
    private var statusItem: NSStatusItem?
    #endif

    public init(viewModel: MenuBarViewModel) {
        self.viewModel = viewModel
    }

    /// Install the status item into the system menu bar. Safe to call more
    /// than once — subsequent calls are ignored if an item already exists.
    public func install() {
        #if canImport(AppKit)
        guard statusItem == nil, viewModel.isMenuBarEnabled else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: "EveryTerm")
        item.button?.toolTip = "EveryTerm"
        updateBadge(on: item)
        item.menu = buildMenu()
        self.statusItem = item
        #endif
    }

    /// Remove the status item. Safe to call even if ``install()`` was never
    /// invoked.
    public func remove() {
        #if canImport(AppKit)
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItem = nil
        #endif
    }

    /// Refresh the status item title/badge and rebuild the dropdown menu.
    public func refresh() {
        #if canImport(AppKit)
        guard let item = statusItem else { return }
        updateBadge(on: item)
        item.menu = buildMenu()
        #endif
    }

    #if canImport(AppKit)
    private func updateBadge(on item: NSStatusItem) {
        item.button?.title = viewModel.badgeText.map { " \($0)" } ?? ""
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(
            withTitle: String(localized: "연결된 세션: \(viewModel.connectedSessionCount)"),
            action: nil,
            keyEquivalent: ""
        )
        menu.addItem(.separator())

        if viewModel.quickConnectItems.isEmpty {
            let empty = NSMenuItem(title: String(localized: "최근 세션 없음"), action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            for (index, session) in viewModel.quickConnectItems.enumerated() {
                let item = NSMenuItem(
                    title: session.name,
                    action: #selector(handleQuickConnect(_:)),
                    keyEquivalent: ""
                )
                item.tag = index
                item.target = self
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        let quit = NSMenuItem(title: String(localized: "EveryTerm 종료"), action: #selector(handleQuit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        return menu
    }

    @objc private func handleQuickConnect(_ sender: NSMenuItem) {
        viewModel.activateQuickConnect(at: sender.tag)
    }

    @objc private func handleQuit() {
        NSApp.terminate(nil)
    }
    #endif
}
