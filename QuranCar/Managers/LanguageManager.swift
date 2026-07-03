//
//  LanguageManager.swift
//  QuranCar
//
//  In-app language switching (System default / English / العربية) that applies
//  immediately without a relaunch and drives a full RTL mirror for Arabic.
//
//  iOS has no native "switch app language live" API, so we swap the class of
//  `Bundle.main` to one that forwards `localizedString(forKey:...)` to the
//  selected `.lproj` bundle (the battle-tested approach). Combined with a root
//  `.environment(\.locale:)` / `.environment(\.layoutDirection:)` and an `.id()`
//  re-render on the main view, every `Text` and `NSLocalizedString` re-resolves
//  in the chosen language on the spot.
//

import SwiftUI
import Foundation
import ObjectiveC

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case arabic = "ar"

    var id: String { rawValue }

    /// The explicit `.lproj` code; `nil` means "follow the device".
    var localeCode: String? {
        switch self {
        case .system: return nil
        case .english: return "en"
        case .arabic: return "ar"
        }
    }

    /// Endonym shown in the picker. "System default" is itself localized.
    var displayName: String {
        switch self {
        case .system: return NSLocalizedString("System default", comment: "Language option: follow device language")
        case .english: return "English"
        case .arabic: return "العربية"
        }
    }
}

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    private static let defaultsKey = "selectedLanguage"

    @Published var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: Self.defaultsKey)
            Bundle.setLanguage(effectiveCode)
        }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.defaultsKey)
        selectedLanguage = stored.flatMap(AppLanguage.init(rawValue:)) ?? .system
        Bundle.setLanguage(effectiveCode)
    }

    /// The concrete code to load, resolving `.system` against the device's
    /// preferred languages (falling back to English) among what we ship.
    var effectiveCode: String {
        if let code = selectedLanguage.localeCode { return code }
        let preferred = Locale.preferredLanguages.first ?? "en"
        return preferred.hasPrefix("ar") ? "ar" : "en"
    }

    var locale: Locale { Locale(identifier: effectiveCode) }

    var layoutDirection: LayoutDirection {
        effectiveCode == "ar" ? .rightToLeft : .leftToRight
    }
}

// MARK: - Bundle language swizzle

private var bundleAssociatedKey: UInt8 = 0

/// A `Bundle` subclass that redirects localized-string lookups to whichever
/// `.lproj` bundle is currently selected.
final class LocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let bundle = objc_getAssociatedObject(self, &bundleAssociatedKey) as? Bundle {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    /// Point `Bundle.main` at the `<code>.lproj` bundle so all subsequent
    /// `Text`/`NSLocalizedString` lookups resolve in that language.
    static func setLanguage(_ code: String) {
        // One-time: promote Bundle.main to our forwarding subclass.
        object_setClass(Bundle.main, LocalizedBundle.self)
        let lprojBundle = Bundle.main.path(forResource: code, ofType: "lproj")
            .flatMap(Bundle.init(path:))
        objc_setAssociatedObject(
            Bundle.main,
            &bundleAssociatedKey,
            lprojBundle,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}
