# Hop

A macOS menu bar app for quick access to frequently used URLs. Configure your links in `~/.config/hop/config.json`, access them from the menu bar dropdown, or press a global hotkey to open a Spotlight-style search panel.

Built with SwiftUI + AppKit, requires macOS 26+.

## Installation

```bash
# Build the app
xcodebuild -scheme hop -configuration Release build

# Copy to Applications
cp -r ~/Library/Developer/Xcode/DerivedData/hop-*/Build/Products/Release/hop.app /Applications/

# Launch
open /Applications/hop.app
```

Grant Accessibility permission when prompted (required for global hotkeys).

To launch at login: System Settings → General → Login Items → add Hop.

## Development

```bash
open hop.xcodeproj
# Build and run (⌘R)
```

See [docs/README.md](docs/README.md) for technical details.
