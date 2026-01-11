import Foundation
import KeyboardShortcuts
import AppKit

extension KeyboardShortcuts.Name {
    static let togglePanel = Self("togglePanel")
}

@MainActor
final class HotkeyManager {
    private let appState: AppState
    private var registeredLinkShortcuts: Set<String> = []

    init(appState: AppState) {
        self.appState = appState
        setupGlobalHotkey()
        setupConfigObservation()
    }

    private func setupGlobalHotkey() {
        KeyboardShortcuts.onKeyUp(for: .togglePanel) { [weak self] in
            Task { @MainActor in
                self?.appState.togglePanel()
            }
        }

        updateHotkeyFromConfig()
    }

    private func setupConfigObservation() {
        func observe() {
            withObservationTracking {
                _ = appState.configManager.config
            } onChange: { [weak self] in
                Task { @MainActor [weak self] in
                    self?.updateHotkeyFromConfig()
                    self?.updateLinkShortcuts()
                    observe()
                }
            }
        }
        observe()
    }

    private func updateHotkeyFromConfig() {
        guard let config = appState.config,
              let hotkeyConfig = config.globalHotkey,
              let shortcut = hotkeyConfig.toKeyboardShortcut() else {
            KeyboardShortcuts.setShortcut(nil, for: .togglePanel)
            return
        }

        KeyboardShortcuts.setShortcut(shortcut, for: .togglePanel)
    }

    private func updateLinkShortcuts() {
        guard let config = appState.config else { return }

        // Get all links with shortcuts
        let linksWithShortcuts = config.allLinks.filter { $0.shortcut != nil }

        // Remove old shortcuts that are no longer in config
        let currentLinkIds = Set(linksWithShortcuts.map(\.id))
        for linkId in registeredLinkShortcuts.subtracting(currentLinkIds) {
            let name = KeyboardShortcuts.Name(linkId)
            KeyboardShortcuts.setShortcut(nil, for: name)
        }

        // Register new/updated shortcuts
        for link in linksWithShortcuts {
            guard let hotkeyConfig = link.shortcut,
                  let shortcut = hotkeyConfig.toKeyboardShortcut() else { continue }

            let name = KeyboardShortcuts.Name(link.id)
            KeyboardShortcuts.setShortcut(shortcut, for: name)

            // Set up handler if not already registered
            if !registeredLinkShortcuts.contains(link.id) {
                let url = link.url
                KeyboardShortcuts.onKeyUp(for: name) {
                    if let urlObj = URL(string: url) {
                        NSWorkspace.shared.open(urlObj)
                    }
                }
            }
        }

        registeredLinkShortcuts = currentLinkIds
    }
}
