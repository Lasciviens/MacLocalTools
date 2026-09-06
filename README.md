# MacLocalTools

A small, local-first macOS utility app written from scratch in Swift/SwiftUI.

## Goals

- Native menu-bar utility for macOS.
- Diagnose sleep and wake problems using built-in macOS tools.
- Keep sensitive data local by default.
- No telemetry, analytics, cloud sync, or background uploads.
- Network access is denied by default and must be explicitly enabled by a feature.

## Current modules

### Sleep Doctor

Reads selected `pmset` diagnostics:

- `pmset -g assertions`
- `pmset -g custom`
- `pmset -g log`

It then extracts likely sleep blockers and recent wake-related events such as DarkWake and MaintenanceWake.

## Run

Requirements: macOS 14+ and a recent Swift toolchain/Xcode.

```bash
swift run
```

Tests:

```bash
swift test
```

## Privacy

MacLocalTools is local-first. The initial version contains no outbound network request implementation. See `SECURITY.md`.

## Independence

This project is implemented from scratch. It does not copy Vorssaint source code.
