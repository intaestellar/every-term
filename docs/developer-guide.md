# EveryTerm Developer Guide

EveryTerm은 SSH · SFTP · RDP · VNC · Telnet · Serial 접속을 단일 macOS 앱에서 제공하는 SwiftPM 기반 프로젝트입니다. 이 가이드는 로컬 개발 환경 세팅, 모듈 구조, 테스트 방법, 배포 파이프라인을 요약합니다.

## 요구 사항

- macOS 14 이상
- Swift 6 toolchain (Xcode 16)
- 선택: `create-dmg`, `codesign`, `xcrun notarytool` (릴리스 빌드)

## 빌드 & 테스트

```bash
# 전체 테스트
swift test --parallel

# 특정 스위트
swift test --filter CommandPaletteFuzzyFilterTests
```

성능 벤치마크는 `EVERYTERM_PERF=1 swift test --filter PerformanceTests` 로 수동 실행합니다.

## 모듈 구조

| Layer | 경로 | 설명 |
|-------|------|------|
| Core | `Sources/EveryTerm/Core/*` | SSH/SFTP/Telnet/Serial/RDP/VNC 어댑터, 터미널 버퍼 |
| Models | `Sources/EveryTerm/Models/*` | `Session`, `SessionGroup`, `KnownHost` 등 도메인 타입 |
| Storage | `Sources/EveryTerm/Storage/*` | `SessionStore`, Keychain |
| UI | `Sources/EveryTerm/UI/*` | SwiftUI 뷰 & 뷰모델 (MainWindow, CommandPalette, Onboarding, MenuBar) |
| Services | `Sources/EveryTerm/Services/*` | Sparkle/AppThemeManager 등 앱 서비스 |
| App | `Sources/EveryTermApp/*` | `@main` 엔트리, `Assets.xcassets` |

## 테마

`TerminalTheme.builtIns` 에 10개 내장 테마(Dracula / Solarized Dark / Nord / One Dark / Gruvbox Dark / Tokyo Night / Catppuccin Mocha / Monokai Pro / macOS Default Light / macOS Default Dark)가 정의되어 있습니다. `AppThemeManager` 가 활성 테마와 사용자 정의 테마를 중앙에서 관리합니다. 사용자 정의는 `ThemeEditorView` 로 편집합니다.

## Host Key Pinning

`Core/SSH/HostKeyValidator.swift` 는 TOFU (Trust-On-First-Use) 정책을 구현합니다. `SSHAdapter` 는 `hostKeyPolicy` 파라미터로 정책을 주입받아 `KnownHost` 모델에 지문을 기록하고, 재접속 시 불일치하면 `SSHConnectionError.hostKeyMismatch` 를 발생시킵니다.

## 업데이트

`Services/Updater/UpdateControllerProtocol.swift` 가 auto-update 파사드이며, `SparkleUpdateController` 가 실제 Sparkle 통합 지점입니다. Sparkle SPM 의존성은 `Package.swift` 에 주석 처리되어 있으며, 실 배포 시 주석을 해제하세요.

## 배포 파이프라인

- `Scripts/sign.sh` — `codesign --entitlements EveryTerm.entitlements` 래퍼
- `Scripts/notarize.sh` — `xcrun notarytool submit` + `xcrun stapler staple`
- `Scripts/create-dmg.sh` — `create-dmg` / `hdiutil` DMG 생성
- `Scripts/generate-appcast.sh` — Sparkle `generate_appcast` 호출
- `.github/workflows/release.yml` — 태그 푸시 시 위 스크립트들을 순차 실행

## 국제화

`Sources/EveryTerm/Resources/{en,ko,ja,zh-Hans}.lproj/Localizable.strings` 에 최소 UI 문자열이 준비되어 있습니다. 새 문자열을 추가할 때는 4개 로케일 모두 업데이트해 주세요.
