import Foundation
import SwiftUI

@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    static let storageKey = "appLanguage"

    /// "" = follow system, "zh-Hans", "zh-Hant", "en"
    @Published var selection: String {
        didSet { UserDefaults.standard.set(selection, forKey: Self.storageKey) }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.storageKey)
        if saved == "zh-Hans" || saved == "zh-Hant" || saved == "en" {
            selection = saved!
        } else if saved == "" {
            selection = ""
        } else {
            selection = "zh-Hant"
        }
    }

    var resolved: String {
        if selection == "zh-Hans" || selection == "zh-Hant" || selection == "en" {
            return selection
        }
        let pref = (Locale.preferredLanguages.first ?? "zh-Hant").lowercased()
        if pref.hasPrefix("en") { return "en" }
        if pref.contains("hans") || pref.hasPrefix("zh-cn") || pref.hasPrefix("zh-sg") {
            return "zh-Hans"
        }
        if pref.hasPrefix("zh") { return "zh-Hant" }
        return "en"
    }

    func t(_ key: String) -> String {
        _ = selection
        if let path = Bundle.main.path(forResource: resolved, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            let value = bundle.localizedString(forKey: key, value: nil, table: nil)
            if value != key { return value }
        }
        if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let bundle = Bundle(path: path) {
            let value = bundle.localizedString(forKey: key, value: nil, table: nil)
            if value != key { return value }
        }
        if let path = Bundle.main.path(forResource: "zh-Hant", ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: key, table: nil)
        }
        return key
    }
}
