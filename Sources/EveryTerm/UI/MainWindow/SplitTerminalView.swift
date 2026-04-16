import SwiftUI

/// Split terminal view supporting horizontal and vertical splits
public struct SplitTerminalView: View {
    @State private var splitLayout: SplitLayout = .single

    public init() {}

    public var body: some View {
        Group {
            switch splitLayout {
            case .single:
                TerminalView()
            case .horizontal:
                HSplitView {
                    TerminalView()
                    TerminalView()
                }
            case .vertical:
                VSplitView {
                    TerminalView()
                    TerminalView()
                }
            }
        }
        .contextMenu {
            Button("Split Horizontally") {
                splitLayout = .horizontal
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])

            Button("Split Vertically") {
                splitLayout = .vertical
            }
            .keyboardShortcut("d", modifiers: .command)

            if splitLayout != .single {
                Divider()
                Button("Remove Split") {
                    splitLayout = .single
                }
            }
        }
    }
}
