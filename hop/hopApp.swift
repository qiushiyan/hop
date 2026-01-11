import SwiftUI
import KeyboardShortcuts

@main
struct HopApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState(configManager: .shared)

    var body: some Scene {
        MenuBarExtra("Hop", systemImage: "link.circle.fill") {
            MenuContentView()
                .environment(appState)
                .onAppear {
                    appDelegate.setup(appState: appState)
                }
        }

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotkeyManager: HotkeyManager?
    private var panelController: FloatingPanelController?
    private var isSetup = false

    func setup(appState: AppState) {
        guard !isSetup else { return }
        isSetup = true

        hotkeyManager = HotkeyManager(appState: appState)
        panelController = FloatingPanelController(appState: appState)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // App launched
    }
}
