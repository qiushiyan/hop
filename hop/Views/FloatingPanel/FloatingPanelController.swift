import AppKit
import SwiftUI

@MainActor
final class FloatingPanelController {
    private var panel: NSPanel?
    private var appState: AppState
    private var observation: Any?

    init(appState: AppState) {
        self.appState = appState
        setupObservation()
    }

    private func setupObservation() {
        // Observe appState.isFloatingPanelVisible changes using withObservationTracking
        func observe() {
            withObservationTracking {
                _ = appState.isFloatingPanelVisible
            } onChange: { [weak self] in
                Task { @MainActor [weak self] in
                    self?.handleVisibilityChange()
                    observe()
                }
            }
        }
        observe()
    }

    private func handleVisibilityChange() {
        if appState.isFloatingPanelVisible {
            showPanel()
        } else {
            hidePanel()
        }
    }

    private func showPanel() {
        if panel == nil {
            createPanel()
        }

        guard let panel = panel else { return }

        // Position near top center of main screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelWidth: CGFloat = 600
            let panelHeight: CGFloat = 400
            let x = screenFrame.midX - panelWidth / 2
            let y = screenFrame.maxY - panelHeight - 100

            panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: true)
        }

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hidePanel() {
        panel?.orderOut(nil)
    }

    private func createPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true

        // Don't show in Mission Control or Exposé
        panel.collectionBehavior = [.transient, .ignoresCycle]

        // Close on escape or focus loss
        panel.hidesOnDeactivate = true

        // Listen for when panel loses focus
        let appState = self.appState
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: panel,
            queue: .main
        ) { _ in
            Task { @MainActor in
                appState.dismissPanel()
            }
        }

        // Host SwiftUI content
        let hostingView = NSHostingView(rootView:
            FloatingPanelContent()
                .environment(appState)
        )
        panel.contentView = hostingView

        self.panel = panel
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
