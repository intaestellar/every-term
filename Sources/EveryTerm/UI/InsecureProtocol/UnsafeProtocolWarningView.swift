import SwiftUI

/// Alert-style surface presented when a user attempts to open an unencrypted
/// protocol (Telnet, VNC without SSH tunnel). The view simply renders the
/// `UnsafeProtocolWarningViewModel` output.
@MainActor
public struct UnsafeProtocolWarningView: View {
    @Binding private var isPresented: Bool
    private let viewModel: UnsafeProtocolWarningViewModel
    @State private var doNotShowAgain: Bool = false

    public init(
        isPresented: Binding<Bool>,
        viewModel: UnsafeProtocolWarningViewModel
    ) {
        self._isPresented = isPresented
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.alertTitle)
                        .font(.headline)
                    Text(viewModel.alertMessage)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Toggle("이 세션에 대해 다시 표시하지 않음", isOn: $doNotShowAgain)
                .toggleStyle(.checkbox)

            HStack {
                Spacer()
                ForEach(Array(viewModel.alertButtons.enumerated()), id: \.offset) { _, button in
                    Button(button.title) {
                        handle(button.action)
                    }
                    .keyboardShortcut(button.action == .proceed ? .defaultAction : .cancelAction)
                }
            }
        }
        .padding(20)
        .frame(minWidth: 420)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(viewModel.alertTitle)
    }

    private func handle(_ action: AcknowledgeAction) {
        if doNotShowAgain {
            viewModel.markIgnored()
        }
        switch action {
        case .proceed:
            viewModel.handleProceed()
        case .cancel:
            viewModel.handleCancel()
        }
        isPresented = false
    }
}
