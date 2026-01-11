# Hop

A macOS menu bar app for quick access to frequently used URLs. Configure your links in `~/.config/hop/config.json`, access them from the menu bar dropdown, or press a global hotkey to open a Spotlight-style search panel.

Requires macOS 26+.

## Installation

Download the latest release from [GitHub Releases](https://github.com/qiushiyan/hop/releases/latest), unzip, and move `hop.app` to `/Applications`.

Grant Accessibility permission when prompted (required for global hotkeys).

To launch at login: System Settings → General → Login Items → add Hop.

## Development

```bash
# Build and run
make build
open build/Release/hop.app

# Or use Xcode
open hop.xcodeproj
```

See [docs/README.md](docs/README.md) for technical details.
