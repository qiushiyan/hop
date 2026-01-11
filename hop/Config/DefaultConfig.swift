import Foundation

enum DefaultConfig {
    static let config = AppConfig(
        version: 1,
        globalHotkey: HotkeyConfig(
            key: "o",
            modifiers: [.command, .shift]
        ),
        categories: [
            Category(
                name: "Getting Started",
                links: [
                    Link(
                        name: "Edit this config",
                        url: "file://~/.config/hop/config.json",
                        keywords: ["settings", "preferences", "configuration"]
                    ),
                    Link(
                        name: "Hop on GitHub",
                        url: "https://github.com/qiushiyan/hop",
                        keywords: ["source", "repo", "code"]
                    )
                ]
            ),
            Category(
                name: "Examples",
                links: [
                    Link(
                        name: "Apple Developer",
                        url: "https://developer.apple.com",
                        keywords: ["docs", "documentation", "swift"]
                    ),
                    Link(
                        name: "SwiftUI Documentation",
                        url: "https://developer.apple.com/documentation/swiftui",
                        keywords: ["ui", "framework"]
                    )
                ]
            )
        ]
    )
}
