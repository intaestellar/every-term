import SwiftUI
import EveryTerm

/// App delegate for AppKit integration
class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let viewModel = MenuBarViewModel()
        let controller = MenuBarController(viewModel: viewModel)
        controller.install()
        self.menuBarController = controller
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

@main
struct EveryTermApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainWindowView()
        }

        #if os(macOS)
        Settings {
            PreferencesView()
        }
        #endif
    }
}
