import SwiftUI

struct MenuContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if let error = appState.configError {
            Section {
                Text("Config Error")
                    .font(.headline)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Divider()
        }

        if let config = appState.config {
            ForEach(config.categories) { category in
                Section(category.name) {
                    ForEach(category.links) { link in
                        Button {
                            appState.openLink(link)
                        } label: {
                            Text(link.name)
                        }
                    }
                }
            }

            if config.categories.isEmpty {
                Text("No links configured")
                    .foregroundStyle(.secondary)
            }
        }

        Divider()

        Button("Edit Config...") {
            appState.configManager.openConfigInEditor()
        }

        SettingsLink {
            Text("Settings...")
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        Button("Quit Hop") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
