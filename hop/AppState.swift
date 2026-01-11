import Foundation
import SwiftUI

@Observable
@MainActor
final class AppState {
    let configManager: ConfigManager
    var isFloatingPanelVisible = false
    var searchQuery = ""

    var config: AppConfig? {
        configManager.config
    }

    var configError: String? {
        configManager.error
    }

    var filteredLinks: [Link] {
        guard let config = config else { return [] }
        let allLinks = config.allLinks

        if searchQuery.isEmpty {
            return allLinks
        }

        return allLinks.filter { $0.matches(query: searchQuery) }
    }

    init(configManager: ConfigManager) {
        self.configManager = configManager
    }

    func openLink(_ link: Link) {
        guard let url = URL(string: link.url) else { return }
        NSWorkspace.shared.open(url)
        dismissPanel()
    }

    func togglePanel() {
        isFloatingPanelVisible.toggle()
        if isFloatingPanelVisible {
            searchQuery = ""
        }
    }

    func dismissPanel() {
        isFloatingPanelVisible = false
        searchQuery = ""
    }
}
