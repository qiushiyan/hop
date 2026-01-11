import Foundation
import AppKit

@Observable
@MainActor
final class ConfigManager {
    private(set) var config: AppConfig?
    private(set) var error: String?

    private let configURL: URL
    private let directoryURL: URL
    private var fileWatcher: DispatchSourceFileSystemObject?
    private var directoryWatcher: DispatchSourceFileSystemObject?

    static let shared = ConfigManager()

    init(configPath: String = "~/.config/hop/config.json") {
        let expandedPath = NSString(string: configPath).expandingTildeInPath
        self.configURL = URL(fileURLWithPath: expandedPath)
        self.directoryURL = configURL.deletingLastPathComponent()

        ensureConfigExists()
        loadConfig()
        startWatching()
    }

    private func ensureConfigExists() {
        let fileManager = FileManager.default

        // Create directory if needed
        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            } catch {
                self.error = "Failed to create config directory: \(error.localizedDescription)"
                return
            }
        }

        // Create default config if file doesn't exist
        if !fileManager.fileExists(atPath: configURL.path) {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(DefaultConfig.config)
                try data.write(to: configURL)
            } catch {
                self.error = "Failed to create default config: \(error.localizedDescription)"
            }
        }
    }

    func loadConfig() {
        do {
            let data = try Data(contentsOf: configURL)
            let decoder = JSONDecoder()
            config = try decoder.decode(AppConfig.self, from: data)
            error = nil
        } catch let decodingError as DecodingError {
            error = formatDecodingError(decodingError)
            config = nil
        } catch {
            self.error = "Failed to load config: \(error.localizedDescription)"
            config = nil
        }
    }

    func saveConfig(_ newConfig: AppConfig) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(newConfig)
            try data.write(to: configURL, options: .atomic)
            // Config will be reloaded by file watcher
        } catch {
            self.error = "Failed to save config: \(error.localizedDescription)"
        }
    }

    func updateGlobalHotkey(_ hotkey: HotkeyConfig?) {
        guard var currentConfig = config else { return }
        currentConfig.globalHotkey = hotkey
        saveConfig(currentConfig)
    }

    func openConfigInEditor() {
        NSWorkspace.shared.open(configURL)
    }

    func openConfigFolder() {
        NSWorkspace.shared.selectFile(configURL.path, inFileViewerRootedAtPath: directoryURL.path)
    }

    var configPath: String {
        configURL.path
    }

    // MARK: - File Watching

    private func startWatching() {
        // Watch the directory for file creation/deletion (handles editors that use rename-and-replace)
        let dirFD = open(directoryURL.path, O_EVTONLY)
        if dirFD >= 0 {
            directoryWatcher = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: dirFD,
                eventMask: [.write, .delete, .rename],
                queue: .main
            )
            directoryWatcher?.setEventHandler { [weak self] in
                self?.loadConfig()
            }
            directoryWatcher?.setCancelHandler {
                close(dirFD)
            }
            directoryWatcher?.resume()
        }

        // Also watch the file directly for in-place edits
        watchFile()
    }

    private func watchFile() {
        fileWatcher?.cancel()
        fileWatcher = nil

        guard FileManager.default.fileExists(atPath: configURL.path) else { return }

        let fileFD = open(configURL.path, O_EVTONLY)
        if fileFD >= 0 {
            fileWatcher = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fileFD,
                eventMask: [.write, .delete, .rename, .extend],
                queue: .main
            )
            fileWatcher?.setEventHandler { [weak self] in
                self?.loadConfig()
            }
            fileWatcher?.setCancelHandler {
                close(fileFD)
            }
            fileWatcher?.resume()
        }
    }

    private func stopWatching() {
        fileWatcher?.cancel()
        fileWatcher = nil
        directoryWatcher?.cancel()
        directoryWatcher = nil
    }

    // MARK: - Error Formatting

    private func formatDecodingError(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, let context):
            return "Missing key '\(key.stringValue)' at \(formatPath(context.codingPath))"
        case .typeMismatch(let type, let context):
            return "Type mismatch for \(type) at \(formatPath(context.codingPath))"
        case .valueNotFound(let type, let context):
            return "Missing value for \(type) at \(formatPath(context.codingPath))"
        case .dataCorrupted(let context):
            return "Invalid JSON: \(context.debugDescription)"
        @unknown default:
            return "Unknown decoding error"
        }
    }

    private func formatPath(_ path: [CodingKey]) -> String {
        if path.isEmpty { return "root" }
        return path.map(\.stringValue).joined(separator: ".")
    }
}
