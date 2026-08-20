import Foundation
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case dark, light
    var id: String { rawValue }
    var titleKey: String { "settings.theme.\(rawValue)" }
    var scheme: ColorScheme { self == .light ? .light : .dark }
}

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    static let storageKey = "appTheme"

    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Self.storageKey) }
    }

    private init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let saved = AppTheme(rawValue: raw) {
            theme = saved
        } else {
            theme = .dark
        }
    }
}
