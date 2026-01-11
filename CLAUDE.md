# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Your are working in a project **Hop**, a macOS menu bar app for quick access to frequently used URLs. Config-driven, keyboard-first. The app is currently for developer personal use only and not released to app store.

## Quick Facts

- **Target**: macOS 26+ (Tahoe)
- **UI**: SwiftUI + AppKit (NSPanel for floating window)
- **Config**: `~/.config/hop/config.json` (JSON, file-watched)
- **Dependencies**: [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) via SPM

## Architecture

```
config.json → ConfigManager → AppState → Views
                                ↓
                          HotkeyManager → KeyboardShortcuts (stateless)
```

- **Source of truth**: JSON config file (not UserDefaults)
- **Global hotkey**: Opens floating search panel (default: ⌘⇧O)
- **Per-link shortcuts**: Optional, JSON-only (no UI)

## Conventions

- `@MainActor` on all stateful classes
- `@Observable` for state management
- File watching via `DispatchSource`
- No AppKit except for `FloatingPanelController` (NSPanel required for proper window behavior)

## Key Files

| File | Purpose |
|------|---------|
| `Config/ConfigManager.swift` | Load/save/watch config |
| `Config/Models.swift` | Codable types + hotkey conversion |
| `AppState.swift` | Central observable state |
| `Views/FloatingPanel/` | NSPanel + SwiftUI search UI |
| `Hotkey/HotkeyManager.swift` | KeyboardShortcuts integration |

## Build & Run

```bash
xcodebuild -scheme hop -configuration Debug build
open hop.xcodeproj  # Or run from Xcode
```

Requires Accessibility permission for global hotkeys.
