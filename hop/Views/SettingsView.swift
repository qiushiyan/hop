import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Form {
            Section("Global Hotkey") {
                LabeledContent("Open Search Panel") {
                    KeyboardShortcuts.Recorder(for: .togglePanel) { shortcut in
                        handleHotkeyChange(shortcut)
                    }
                }

                Text("Press the shortcut to open the floating search panel from anywhere.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Configuration") {
                LabeledContent("Config File") {
                    Text(appState.configManager.configPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                HStack {
                    Button("Open Config File") {
                        appState.configManager.openConfigInEditor()
                    }

                    Button("Reveal in Finder") {
                        appState.configManager.openConfigFolder()
                    }
                }
            }

            if let error = appState.configError {
                Section("Config Error") {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Accessibility") {
                AccessibilityPermissionView()
            }

            Section("About") {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }

                Text("Hop is a menu bar app for quick access to your favorite links.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 400)
    }

    private func handleHotkeyChange(_ shortcut: KeyboardShortcuts.Shortcut?) {
        if let shortcut = shortcut {
            let hotkeyConfig = HotkeyConfig.from(shortcut: shortcut)
            appState.configManager.updateGlobalHotkey(hotkeyConfig)
        } else {
            appState.configManager.updateGlobalHotkey(nil)
        }
    }
}

struct AccessibilityPermissionView: View {
    @State private var hasPermission = AXIsProcessTrusted()

    var body: some View {
        HStack {
            if hasPermission {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Accessibility permission granted")
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading) {
                    Text("Accessibility permission required")
                    Text("Global hotkeys need accessibility access to work.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Open Settings") {
                    openAccessibilitySettings()
                }
            }
        }
        .onAppear {
            checkPermission()
        }
    }

    private func checkPermission() {
        hasPermission = AXIsProcessTrusted()
    }

    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)

        // Check again after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            checkPermission()
        }
    }
}
