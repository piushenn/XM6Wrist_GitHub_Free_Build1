# XM6 Wrist — watchOS source + GitHub free online build

**Aim:** An independent Apple Watch Series 11 app for Sony WF-1000XM6 earbuds.

**Current, honest state:** Apple Watch playback/volume UI, touch-control instructions, and a **read-only GATT Bluetooth probe** are included. **Noise cancellation, ambient level and Sony EQ are NOT controlled by this build.** The relevant Sony configuration interface may not be accessible from public watchOS Bluetooth APIs.

## Start from Windows
Read [`guide/START-HERE-WINDOWS.md`](guide/START-HERE-WINDOWS.md). Commit this folder to a **public** GitHub repository to trigger the `.github/workflows/watchos-build.yml` free macOS build. No Mac or paid account is needed to **compile**.

The resulting unsigned Simulator `.app` artifact is **not installable on your real Apple Watch**. Real hardware testing and Sony Bluetooth protocol feasibility remain unresolved.

## Project files
- `XM6Wrist.xcodeproj/` — Xcode project + shared scheme
- `XM6Wrist/` — SwiftUI watch-only app, asset catalog, Bluetooth GATT probe
- `.github/workflows/watchos-build.yml` — cloud macOS-26 compilation workflow

## References
- GitHub runner availability and free public runners: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
- Apple install/signing requirements: https://help.apple.com/xcode/mac/current/en.lproj/dev5a825a1ca.html
- Apple independent watchOS apps: https://developer.apple.com/documentation/watchos-apps/creating-independent-watchos-apps
