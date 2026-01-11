# Hop Technical Guide

## Overview

Hop is a menu bar utility that provides quick access to URLs via dropdown menu and a Spotlight-style floating search panel. It's designed as a "config-file-driven" app where `~/.config/hop/config.json` is the single source of truth.

## Design Decisions

### Why JSON Config Over UserDefaults

- **Portability**: Users can version control, sync, or share their config
- **Transparency**: Human-readable, editable in any text editor
- **Unix philosophy**: Follows `~/.config/` convention familiar to developers

### Why NSPanel Over Pure SwiftUI

SwiftUI cannot create a proper Spotlight-like floating panel. The required behaviors need AppKit:

- `.nonactivatingPanel` style mask (don't steal focus from other apps)
- `.floating` window level (stay above other windows)
- `.transient` collection behavior (don't appear in Mission Control)
- `hidesOnDeactivate` (dismiss on focus loss)

The solution: thin AppKit wrapper (`FloatingPanelController`) hosting SwiftUI content.

### Why KeyboardShortcuts in "Stateless" Mode

KeyboardShortcuts normally persists to UserDefaults. We bypass this:

1. Read hotkey config from JSON
2. Call `KeyboardShortcuts.setShortcut()` to register programmatically
3. When user records new hotkey in Settings, write directly to JSON
4. File watcher triggers reload → hotkeys re-register

This keeps JSON as the only storage location.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        HopApp                               │
│  @main entry, owns AppState, sets up MenuBarExtra + Settings│
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
      ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
      │ ConfigManager│  │  AppState   │  │ AppDelegate │
      │ Load/save/   │◄─│ Observable  │──│ Setup mgrs  │
      │ watch JSON   │  │ state       │  │ on launch   │
      └─────────────┘  └─────────────┘  └─────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
      ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
      │MenuContentView│ │FloatingPanel│  │HotkeyManager│
      │ Dropdown UI  │  │ Search UI   │  │ Shortcuts   │
      └─────────────┘  └─────────────┘  └─────────────┘
```

---

## Core Components

### ConfigManager ([Config/ConfigManager.swift](../hop/Config/ConfigManager.swift))

Responsibilities:
- Create default config on first launch
- Load and decode JSON with descriptive error messages
- Watch file and directory for changes (handles editors that use rename-and-replace)
- Save config atomically

File watching uses dual `DispatchSource` watchers—one on the directory (catches renames), one on the file (catches in-place edits).

### AppState ([AppState.swift](../hop/AppState.swift))

Central `@Observable` state holding:
- Reference to `ConfigManager`
- `isFloatingPanelVisible` toggle
- `searchQuery` for filtering
- Computed `filteredLinks` based on query

All UI components read from this single state object.

### FloatingPanelController ([Views/FloatingPanel/FloatingPanelController.swift](../hop/Views/FloatingPanel/FloatingPanelController.swift))

The only significant AppKit code. Creates an `NSPanel` with proper window behaviors and hosts `FloatingPanelContent` via `NSHostingView`.

Observes `appState.isFloatingPanelVisible` using `withObservationTracking` and shows/hides the panel accordingly.

### HotkeyManager ([Hotkey/HotkeyManager.swift](../hop/Hotkey/HotkeyManager.swift))

Bridges config to KeyboardShortcuts library:
- Registers global hotkey from `config.globalHotkey`
- Registers per-link shortcuts from `link.shortcut`
- Updates registrations when config changes
- Triggers `appState.togglePanel()` on global hotkey

---

## Config Schema

```json
{
  "version": 1,
  "globalHotkey": {
    "key": "o",
    "modifiers": ["command", "shift"]
  },
  "categories": [
    {
      "name": "Category Name",
      "links": [
        {
          "name": "Link Name",
          "url": "https://example.com",
          "keywords": ["optional", "search", "terms"],
          "shortcut": {
            "key": "e",
            "modifiers": ["command", "control"]
          }
        }
      ]
    }
  ]
}
```

- `version`: Schema version for future migrations
- `globalHotkey`: Opens floating panel
- `keywords`: Optional array for better search matching
- `shortcut`: Optional per-link hotkey (JSON-only, no Settings UI)

See [Config/Models.swift](../hop/Config/Models.swift) for Codable definitions.

---

## Data Flow

### Opening a Link

```
User clicks link in menu
  → MenuContentView calls appState.openLink(link)
    → NSWorkspace.shared.open(url)
    → appState.dismissPanel() (if panel was open)
```

### Recording a New Hotkey

```
User records in Settings
  → KeyboardShortcuts.Recorder captures keystroke
  → SettingsView.handleHotkeyChange() called
    → configManager.updateGlobalHotkey(newConfig)
      → Writes to JSON file
        → File watcher triggers loadConfig()
          → HotkeyManager observes config change
            → Calls KeyboardShortcuts.setShortcut()
```

### Config File Changed Externally

```
User edits ~/.config/hop/config.json
  → DispatchSource fires
    → configManager.loadConfig()
      → appState.config updated (via @Observable)
        → All views re-render automatically
        → HotkeyManager re-registers shortcuts
```

---

## Build Configuration

Key project settings in `project.pbxproj`:

| Setting | Value | Purpose |
|---------|-------|---------|
| `MACOSX_DEPLOYMENT_TARGET` | 26.0 | macOS Tahoe |
| `ENABLE_APP_SANDBOX` | NO | Access ~/.config, global hotkeys |
| `INFOPLIST_KEY_LSUIElement` | YES | No dock icon (agent app) |

SPM dependency: `https://github.com/sindresorhus/KeyboardShortcuts` (2.0.0+)

---

## Testing Checklist

| Feature | Verification |
|---------|--------------|
| First launch | Creates `~/.config/hop/` and default config |
| Menu dropdown | Shows categories and links from config |
| Link opening | Opens URL in default browser |
| Global hotkey | ⌘⇧O opens floating panel |
| Panel search | Filters by name, URL, and keywords |
| Panel keyboard | ↑↓ navigate, Enter opens, Escape dismisses |
| File watching | Edit config externally → UI updates |
| Settings | Record new hotkey → persists to JSON |
| Error handling | Malformed JSON → shows error in menu, doesn't crash |

---

## Extension Points

**Adding new config fields**: Update `Models.swift`, handle in relevant manager.

**Custom search algorithm**: Modify `Link.matches(query:)` in Models.swift.

**Different panel trigger**: Add new `KeyboardShortcuts.Name` in HotkeyManager.

**Per-link shortcuts UI**: Add list with recorders to SettingsView (currently JSON-only).
