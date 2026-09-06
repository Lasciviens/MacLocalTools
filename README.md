# MacLocalTools

A local-first macOS menu-bar utility written from scratch in Swift/SwiftUI.

## Principles

- Native macOS app.
- No telemetry, analytics, cloud sync, or background uploads.
- No arbitrary shell execution.
- Clipboard history is RAM-only and disappears when the app exits.
- Network implementation is absent by default.
- Prefer public/supported macOS APIs over private or privileged interfaces.

## Modules

### Monitor

- CPU load from Mach host statistics.
- Memory usage from Mach VM statistics.
- Battery percentage, charging state, power source, and time estimate through IOKit power-source APIs.
- Temperature is intentionally not implemented yet because reliable Apple Silicon sensor access requires privileged/private mechanisms that this project currently avoids.

### Sleep Doctor

Reads only built-in `pmset` diagnostics:

- `pmset -g assertions`
- `pmset -g custom`
- `pmset -g log`

It extracts current sleep blockers, DarkWake/MaintenanceWake activity, and creates simple interpretations for items such as `sharingd`, TCPKeepAlive, Power Nap, and frequent DarkWake activity.

### Clipboard

- Watches text copied through `NSPasteboard`.
- Keeps up to 50 entries.
- Stores history only in process memory.
- Does not persist clipboard contents to disk.

### Window Manager

Uses macOS Accessibility APIs to move the focused window to:

- Left half
- Right half
- Maximize
- Center

Accessibility permission is required. No Screen Recording permission is used.

### Safe Tweaks

Currently provides fixed Finder/system preference operations:

- Show/hide hidden Finder files.
- Show/hide all file extensions.

Only allow-listed executables and fixed argument structures are used (`pmset`, `defaults`, `killall`).

## Run

Requirements: macOS 14+ and a recent Xcode/Swift toolchain.

```bash
swift run
```

Tests:

```bash
swift test
```

GitHub Actions also runs `swift build` and `swift test` on pushes to `main` and pull requests.

## Privacy and security

See `SECURITY.md`.

## Independence

This project is implemented from scratch. It does not copy Vorssaint source code.
