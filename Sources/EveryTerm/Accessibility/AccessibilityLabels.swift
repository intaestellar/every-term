import Foundation

/// Central catalog of VoiceOver labels and hints so the UI layer stays
/// localisation-friendly and we can verify uniqueness in tests.
public enum AccessibilityLabels {
    // MARK: - Core labels

    public static let newSession = "새 세션"
    public static let closeTab = "탭 닫기"
    public static let connect = "연결"
    public static let disconnect = "연결 해제"

    // MARK: - Label + hint pairs

    public static let newSessionLabel = "새 세션 만들기"
    public static let newSessionHint = "새 원격 세션을 추가합니다"

    public static let closeTabLabel = "현재 탭 닫기"
    public static let closeTabHint = "선택한 탭을 닫습니다"

    public static let connectLabel = "세션 연결"
    public static let connectHint = "선택한 세션으로 접속합니다"

    public static let disconnectLabel = "세션 연결 해제"
    public static let disconnectHint = "현재 연결을 종료합니다"

    public static let openPreferencesLabel = "환경설정 열기"
    public static let openPreferencesHint = "EveryTerm 환경설정을 엽니다"

    public static let openCommandPaletteLabel = "커맨드 팔레트"
    public static let openCommandPaletteHint = "Cmd+Shift+P — 세션 및 명령 검색"

}
