# EveryTerm

EveryTerm is a multi-protocol terminal and remote-access client for macOS.
It consolidates SSH, SFTP, RDP, VNC, Telnet and Serial connections into a
single polished interface, designed for power users who juggle servers,
workstations, and embedded devices from the same laptop.

## Highlights

- **Protocols**: SSH (with jump hosts, agent forwarding, host key pinning),
  SFTP browser and transfer, RDP via FreeRDP, VNC via LibVNCClient,
  Telnet, and USB Serial consoles.
- **Productivity**: command palette (Cmd+Shift+P), Spotlight indexing,
  macros, multi-exec, SSH tunnels, tabbed sessions, custom themes.
- **Security**: SecureBytes-backed credential handling, Keychain storage,
  Hardened Runtime, TOFU (trust-on-first-use) host key pinning for SSH hosts.
- **Themes**: ten curated built-ins (Dracula, Solarized Dark, Nord, One
  Dark, Gruvbox Dark, Tokyo Night, Catppuccin Mocha, Monokai Pro, macOS
  Default Light / Dark) plus iTerm2 `.itermcolors` import and a custom
  theme editor.

## Requirements

- macOS 14 (Sonoma) or newer. macOS 15 Sequoia is fully supported.
- Apple Silicon or Intel.
- Xcode 16 toolchain if you build from source.

## Install via Homebrew

The recommended install path is the Homebrew cask:

```sh
brew tap everyterm/tap
brew install --cask everyterm
```

Direct DMG downloads are also available on the
[GitHub Releases](https://github.com/everyterm/everyterm/releases) page.

## Build from source

```sh
swift test --parallel
swift build -c release
```

FreeRDP and LibVNCClient XCFrameworks must be pre-built via
`Scripts/build-freerdp.sh` and `Scripts/build-libvncclient.sh` before the
RDP and VNC adapters will link. See `docs/developer-guide.md` for the full
workflow.

## Project status

EveryTerm is tracked in the `.run/plans/` directory as a series of TDD
sub-projects (SP-1 through SP-5). Contributions, bug reports, and feature
requests are welcome — see `CONTRIBUTING.md`.

## License

EveryTerm is released under the terms of the LICENSE file included in this
repository.
