import SwiftUI

/// Displays file transfer progress for queued, active, and completed transfers.
public struct FileTransferView: View {
    public let transfers: [TransferItem]
    public var onCancel: ((UUID) -> Void)?
    public var onPause: ((UUID) -> Void)?
    public var onResume: ((UUID) -> Void)?

    public init(
        transfers: [TransferItem],
        onCancel: ((UUID) -> Void)? = nil,
        onPause: ((UUID) -> Void)? = nil,
        onResume: ((UUID) -> Void)? = nil
    ) {
        self.transfers = transfers
        self.onCancel = onCancel
        self.onPause = onPause
        self.onResume = onResume
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Transfers")
                    .font(.headline)
                Spacer()
                Text("\(activeCount) active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            Divider()

            if transfers.isEmpty {
                Text("No transfers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(transfers) { item in
                    TransferItemRow(
                        item: item,
                        onCancel: { onCancel?(item.id) },
                        onPause: { onPause?(item.id) },
                        onResume: { onResume?(item.id) }
                    )
                }
                .listStyle(.inset)
            }
        }
    }

    private var activeCount: Int {
        transfers.filter { item in
            if case .transferring = item.state { return true }
            if case .queued = item.state { return true }
            return false
        }.count
    }
}

// MARK: - Transfer Item Row

struct TransferItemRow: View {
    let item: TransferItem
    var onCancel: () -> Void
    var onPause: () -> Void
    var onResume: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: item.direction == .upload ? "arrow.up.circle" : "arrow.down.circle")
                    .foregroundStyle(item.direction == .upload ? .blue : .green)

                Text(filename)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                actionButtons
            }

            // Progress
            switch item.state {
            case .transferring(let progress):
                ProgressView(value: progress)
                HStack {
                    Text(formattedSpeed(item.speed))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formattedRemaining(item: item, progress: progress))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            case .queued:
                Text("Queued")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            case .completed:
                Text("Completed")
                    .font(.caption2)
                    .foregroundStyle(.green)
            case .failed(let error):
                Text("Failed: \(error.localizedDescription)")
                    .font(.caption2)
                    .foregroundStyle(.red)
            case .cancelled:
                Text("Cancelled")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var filename: String {
        (item.direction == .upload ? item.sourcePath : item.destinationPath)
            .components(separatedBy: "/").last ?? "Unknown"
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch item.state {
        case .transferring:
            Button(action: onPause) {
                Image(systemName: "pause.circle")
            }
            .buttonStyle(.borderless)
            Button(action: onCancel) {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.borderless)
        case .queued:
            Button(action: onResume) {
                Image(systemName: "play.circle")
            }
            .buttonStyle(.borderless)
            Button(action: onCancel) {
                Image(systemName: "xmark.circle")
            }
            .buttonStyle(.borderless)
        default:
            EmptyView()
        }
    }

    private func formattedSpeed(_ bytesPerSec: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return "\(formatter.string(fromByteCount: Int64(bytesPerSec)))/s"
    }

    private func formattedRemaining(item: TransferItem, progress: Double) -> String {
        guard progress > 0, item.speed > 0 else { return "--" }
        let remainingBytes = Double(item.totalBytes) * (1.0 - progress)
        let seconds = Int(remainingBytes / item.speed)
        if seconds < 60 { return "\(seconds)s remaining" }
        let minutes = seconds / 60
        return "\(minutes)m \(seconds % 60)s remaining"
    }
}
