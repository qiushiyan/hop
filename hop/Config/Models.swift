import Foundation
import AppKit
import KeyboardShortcuts
import Carbon.HIToolbox

struct AppConfig: Codable, Equatable {
    var version: Int = 1
    var globalHotkey: HotkeyConfig?
    var categories: [Category] = []

    var allLinks: [Link] {
        categories.flatMap(\.links)
    }
}

struct Category: Codable, Equatable, Identifiable {
    var id: String { name }
    var name: String
    var links: [Link] = []
}

struct Link: Codable, Equatable, Identifiable {
    var id: String { url }
    var name: String
    var url: String
    var keywords: [String]?
    var shortcut: HotkeyConfig?

    func matches(query: String) -> Bool {
        let query = query.lowercased()
        if name.localizedCaseInsensitiveContains(query) { return true }
        if url.localizedCaseInsensitiveContains(query) { return true }
        if let keywords = keywords {
            return keywords.contains { $0.localizedCaseInsensitiveContains(query) }
        }
        return false
    }
}

struct HotkeyConfig: Codable, Equatable {
    var key: String
    var modifiers: [ModifierKey]

    enum ModifierKey: String, Codable {
        case command
        case control
        case option
        case shift
    }

    func toKeyboardShortcut() -> KeyboardShortcuts.Shortcut? {
        guard let keyCode = keyStringToKeyCode(key) else { return nil }

        var eventModifiers: NSEvent.ModifierFlags = []
        for modifier in modifiers {
            switch modifier {
            case .command: eventModifiers.insert(.command)
            case .control: eventModifiers.insert(.control)
            case .option: eventModifiers.insert(.option)
            case .shift: eventModifiers.insert(.shift)
            }
        }

        return KeyboardShortcuts.Shortcut(carbonKeyCode: keyCode, carbonModifiers: Int(eventModifiers.carbonFlags))
    }

    static func from(shortcut: KeyboardShortcuts.Shortcut) -> HotkeyConfig? {
        guard let keyString = keyCodeToKeyString(Int(shortcut.carbonKeyCode)) else { return nil }

        var modifiers: [ModifierKey] = []
        let flags = shortcut.modifiers
        if flags.contains(.command) { modifiers.append(.command) }
        if flags.contains(.control) { modifiers.append(.control) }
        if flags.contains(.option) { modifiers.append(.option) }
        if flags.contains(.shift) { modifiers.append(.shift) }

        return HotkeyConfig(key: keyString, modifiers: modifiers)
    }
}

// Key code mappings
private func keyStringToKeyCode(_ key: String) -> Int? {
    let mapping: [String: Int] = [
        "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D,
        "e": kVK_ANSI_E, "f": kVK_ANSI_F, "g": kVK_ANSI_G, "h": kVK_ANSI_H,
        "i": kVK_ANSI_I, "j": kVK_ANSI_J, "k": kVK_ANSI_K, "l": kVK_ANSI_L,
        "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O, "p": kVK_ANSI_P,
        "q": kVK_ANSI_Q, "r": kVK_ANSI_R, "s": kVK_ANSI_S, "t": kVK_ANSI_T,
        "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X,
        "y": kVK_ANSI_Y, "z": kVK_ANSI_Z,
        "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3,
        "4": kVK_ANSI_4, "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7,
        "8": kVK_ANSI_8, "9": kVK_ANSI_9,
        "space": kVK_Space, "return": kVK_Return, "tab": kVK_Tab,
        "escape": kVK_Escape, "delete": kVK_Delete,
        "up": kVK_UpArrow, "down": kVK_DownArrow,
        "left": kVK_LeftArrow, "right": kVK_RightArrow,
    ]
    return mapping[key.lowercased()]
}

private func keyCodeToKeyString(_ keyCode: Int) -> String? {
    let mapping: [Int: String] = [
        kVK_ANSI_A: "a", kVK_ANSI_B: "b", kVK_ANSI_C: "c", kVK_ANSI_D: "d",
        kVK_ANSI_E: "e", kVK_ANSI_F: "f", kVK_ANSI_G: "g", kVK_ANSI_H: "h",
        kVK_ANSI_I: "i", kVK_ANSI_J: "j", kVK_ANSI_K: "k", kVK_ANSI_L: "l",
        kVK_ANSI_M: "m", kVK_ANSI_N: "n", kVK_ANSI_O: "o", kVK_ANSI_P: "p",
        kVK_ANSI_Q: "q", kVK_ANSI_R: "r", kVK_ANSI_S: "s", kVK_ANSI_T: "t",
        kVK_ANSI_U: "u", kVK_ANSI_V: "v", kVK_ANSI_W: "w", kVK_ANSI_X: "x",
        kVK_ANSI_Y: "y", kVK_ANSI_Z: "z",
        kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3",
        kVK_ANSI_4: "4", kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7",
        kVK_ANSI_8: "8", kVK_ANSI_9: "9",
        kVK_Space: "space", kVK_Return: "return", kVK_Tab: "tab",
        kVK_Escape: "escape", kVK_Delete: "delete",
        kVK_UpArrow: "up", kVK_DownArrow: "down",
        kVK_LeftArrow: "left", kVK_RightArrow: "right",
    ]
    return mapping[keyCode]
}

// Extension to convert NSEvent.ModifierFlags to Carbon modifier flags
extension NSEvent.ModifierFlags {
    var carbonFlags: UInt32 {
        var carbon: UInt32 = 0
        if contains(.command) { carbon |= UInt32(cmdKey) }
        if contains(.option) { carbon |= UInt32(optionKey) }
        if contains(.control) { carbon |= UInt32(controlKey) }
        if contains(.shift) { carbon |= UInt32(shiftKey) }
        return carbon
    }
}
