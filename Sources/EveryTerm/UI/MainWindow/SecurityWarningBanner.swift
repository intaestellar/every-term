import SwiftUI

/// Banner displayed above tabs/terminals when the active session uses a
/// protocol that transmits data in cleartext (e.g., Telnet). The banner is
/// intentionally compact so it stays visible without obscuring terminal
/// content, and it disappears automatically when the session is not
/// insecure.
public struct SecurityWarningBanner: View {
    public let sessionType: SessionType

    public init(sessionType: SessionType) {
        self.sessionType = sessionType
    }

    /// Returns `true` for protocols that do not encrypt traffic.
    public static func isInsecure(_ type: SessionType) -> Bool {
        switch type {
        case .telnet:
            return true
        case .ssh, .local, .rdp, .vnc, .serial:
            return false
        }
    }

    public var body: some View {
        if Self.isInsecure(sessionType) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text("Telnet 연결은 암호화되지 않습니다. 비밀번호와 명령어가 평문으로 전송됩니다.")
                    .font(.caption)
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.yellow.opacity(0.15))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color.yellow.opacity(0.4)),
                alignment: .bottom
            )
            .accessibilityLabel("Insecure protocol warning")
        }
    }
}
