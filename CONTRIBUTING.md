# Contributing to EveryTerm

Thanks for taking the time to improve EveryTerm! This document summarises
how the project is organised and what we expect from contributions.

## Development workflow

EveryTerm is written in Swift 6 with Swift Testing (`@Suite`, `@Test`,
`#expect`). Follow the Kent Beck TDD loop: RED → GREEN → REFACTOR.

```sh
swift test --parallel
swift build
```

The CI runs `swift test --parallel` on `macos-15`; keep the test suite
green locally before submitting a PR.

## Architecture

See `docs/developer-guide.md` for a deeper tour. In short:

- **Sources/EveryTerm/** — library code, grouped by Core / Models / UI /
  Services / Storage / Themes / Spotlight / Accessibility.
- **Sources/EveryTermApp/** — the macOS executable entry point.
- **Tests/EveryTermTests/** — Swift Testing suites.

Credentials must never land in plain `String` fields; use `SecureBytes` or
Keychain indirection. See `Tests/EveryTermTests/Audit/` for the static
audits that enforce this.

## Pull requests

- Keep PRs focused; reference the relevant sub-project plan under
  `.run/plans/`.
- Make sure `swift test --parallel` passes.
- Add or update tests alongside new behaviour.
- Respect the project's Code of Conduct.

Welcome aboard!
