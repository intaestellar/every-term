import SwiftUI

/// Built-in text editor for viewing and editing remote files.
/// Uses SwiftUI TextEditor with syntax language detection via SyntaxLanguageDetector.
public struct TextEditorView: View {
    @Binding public var content: String
    public let filename: String
    public let isReadOnly: Bool
    public var onSave: ((String) -> Void)?

    @State private var hasChanges: Bool = false

    public init(
        content: Binding<String>,
        filename: String,
        isReadOnly: Bool = false,
        onSave: ((String) -> Void)? = nil
    ) {
        self._content = content
        self.filename = filename
        self.isReadOnly = isReadOnly
        self.onSave = onSave
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header bar
            headerBar

            Divider()

            // Editor
            TextEditor(text: isReadOnly ? .constant(content) : $content)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.visible)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: content) { _, _ in
                    hasChanges = true
                }

            Divider()

            // Status bar
            statusBar
        }
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundStyle(.secondary)

            Text(filename)
                .font(.system(.caption, design: .monospaced))
                .lineLimit(1)

            if hasChanges {
                Circle()
                    .fill(.orange)
                    .frame(width: 6, height: 6)
            }

            Spacer()

            if !isReadOnly, let onSave = onSave {
                Button("Save") {
                    onSave(content)
                    hasChanges = false
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("s", modifiers: .command)
                .disabled(!hasChanges)
            }

            if isReadOnly {
                Label("Read Only", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            // Language label
            Text(detectedLanguage.rawValue.uppercased())
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.15))
                )

            Spacer()

            // Character count
            Text("\(content.count) characters")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Line count
            Text("\(lineCount) lines")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.bar)
    }

    // MARK: - Helpers

    private var detectedLanguage: SyntaxLanguage {
        SyntaxLanguageDetector.detect(filename: filename)
    }

    private var lineCount: Int {
        content.components(separatedBy: .newlines).count
    }
}
