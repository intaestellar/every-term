import SwiftUI

/// Placeholder view for VNC sessions.
///
/// The `VNCAdapter` currently throws `RemoteConnectionError.notImplemented`
/// because the LibVNCClient XCFramework is not yet bundled. Until that
/// integration lands, this view renders a user-friendly explanation
/// instead of attempting to display a framebuffer.
public struct VNCView: View {
    public let host: String

    public init(host: String) {
        self.host = host
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.on.rectangle.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("LibVNCClient 통합 예정")
                .font(.title2)
                .fontWeight(.semibold)

            Text("VNC 뷰어는 LibVNCClient XCFramework 통합 이후 제공됩니다.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if !host.isEmpty {
                Text("대상 호스트: \(host)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
