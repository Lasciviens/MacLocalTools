# Security and Privacy

MacLocalTools is designed as a local-first macOS utility.

## Current guarantees

- No telemetry or analytics SDKs.
- No cloud sync.
- No outbound HTTP implementation in the initial codebase.
- `NetworkPolicy` defaults to `.denied`.
- External processes are executed with `Process` using a fixed executable allow-list.
- Shell command strings are not evaluated.
- The current allow-list contains only `/usr/bin/pmset`.

## Data handling

Sleep diagnostics are read from local macOS `pmset` output and rendered locally in the app. The initial version does not persist these diagnostics to disk.

## Future network-enabled features

If a future feature needs network access, it should:

1. Be opt-in and clearly identified.
2. Use the centralized network policy.
3. Document the destination and data being sent.
4. Avoid sending clipboard, sleep diagnostics, file names, or other sensitive local information unless explicitly required by the user.

## Reporting security issues

Open a GitHub issue without including private machine data, tokens, passwords, clipboard contents, or full diagnostic logs.
