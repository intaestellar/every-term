import Foundation

@MainActor
public final class UnsafeProtocolWarningViewModel {
    private let session: Session
    private let storage: UnsafeWarningStorage
    private let vncSshTunnelSessionId: UUID?
    private let onAcknowledge: ((AcknowledgeAction) -> Void)?

    public init(
        session: Session,
        storage: UnsafeWarningStorage,
        vncSshTunnelSessionId: UUID? = nil,
        onAcknowledge: ((AcknowledgeAction) -> Void)? = nil
    ) {
        self.session = session
        self.storage = storage
        self.vncSshTunnelSessionId = vncSshTunnelSessionId
        self.onAcknowledge = onAcknowledge
    }

    public var shouldPresentAlert: Bool {
        if storage.isIgnored(for: session.id) {
            return false
        }
        switch session.type {
        case .telnet:
            return true
        case .vnc:
            return vncSshTunnelSessionId == nil
        default:
            return false
        }
    }

    public var alertTitle: String {
        switch session.type {
        case .telnet:
            return "암호화되지 않은 Telnet 연결"
        case .vnc:
            return "암호화되지 않은 VNC 연결"
        default:
            return "암호화되지 않은 연결"
        }
    }

    public var alertMessage: String {
        "이 프로토콜은 자격증명과 세션 데이터를 평문으로 전송합니다. "
            + "계속 진행하기 전 보안 위험을 이해하고 있는지 확인하세요."
    }

    public var alertButtons: [UnsafeWarningButton] {
        [
            UnsafeWarningButton(title: "이해하고 계속", action: .proceed),
            UnsafeWarningButton(title: "취소", action: .cancel)
        ]
    }

    public func handleProceed() {
        onAcknowledge?(.proceed)
    }

    public func handleCancel() {
        onAcknowledge?(.cancel)
    }

    public func markIgnored() {
        storage.setIgnored(true, for: session.id)
    }
}
