import SwiftUI

/// First-run welcome screen. Presents the EveryTerm logo, quick-start CTAs, and
/// a list of recent sessions pulled from `WelcomeViewModel`.
///
/// - Important: **Plan Step 1-9 미완** — `Localizable.strings` 파일(4개 언어)은
///   작성돼 있으나 소스 코드의 한국어 하드코딩이 `String(localized:)` 로 치환되지
///   않았습니다. 국제화 활성화는 별도 PR에서 진행합니다.
@MainActor
public struct WelcomeView: View {
    private let viewModel: WelcomeViewModel
    private let onCTATapped: ((WelcomeCTAButton) -> Void)?
    private let onSessionSelected: ((Session) -> Void)?

    public init(
        viewModel: WelcomeViewModel,
        onCTATapped: ((WelcomeCTAButton) -> Void)? = nil,
        onSessionSelected: ((Session) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onCTATapped = onCTATapped
        self.onSessionSelected = onSessionSelected
    }

    public var body: some View {
        VStack(spacing: 24) {
            header

            ctaRow

            Divider()

            recentSessionsSection
        }
        .padding(32)
        .frame(minWidth: 480, minHeight: 360)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("EveryTerm 시작하기")
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "terminal.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(.tint)
            Text("EveryTerm에 오신 것을 환영합니다")
                .font(.title).bold()
            Text("하나의 앱에서 SSH · SFTP · RDP · VNC · Telnet · Serial")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var ctaRow: some View {
        HStack(spacing: 12) {
            ForEach(Array(viewModel.ctaButtons.enumerated()), id: \.offset) { _, button in
                Button {
                    onCTATapped?(button)
                } label: {
                    Label(button.title, systemImage: button.systemImage)
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .accessibilityLabel(button.title)
            }
        }
    }

    @ViewBuilder
    private var recentSessionsSection: some View {
        if viewModel.shouldShowEmptyState {
            VStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
                Text("최근 세션이 없습니다")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("최근 세션")
                    .font(.headline)
                ForEach(viewModel.recentSessions) { session in
                    Button {
                        onSessionSelected?(session)
                    } label: {
                        HStack {
                            Image(systemName: "terminal")
                            VStack(alignment: .leading) {
                                Text(session.name).fontWeight(.medium)
                                Text(session.host).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(session.name), \(session.host)")
                }
            }
        }
    }
}
