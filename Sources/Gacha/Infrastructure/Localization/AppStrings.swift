import Foundation

enum AppStrings {
  static func localized(
    _ key: String,
    preferences: [String] = Locale.preferredLanguages,
    bundle: Bundle = .module
  ) -> String {
    let localizations =
      CFBundleCopyLocalizationsForPreferences(
        bundle.localizations as CFArray,
        preferences as CFArray
      ) as? [String] ?? []

    for localization in localizations {
      if let value = localizedString(key, localization: localization, bundle: bundle) {
        return value
      }
    }

    return bundle.localizedString(forKey: key, value: key, table: nil)
  }

  private static func localizedString(
    _ key: String,
    localization: String,
    bundle: Bundle
  ) -> String? {
    guard
      let localizationURL = bundle.url(forResource: localization, withExtension: "lproj"),
      let localizedBundle = Bundle(url: localizationURL)
    else {
      return nil
    }

    let value = localizedBundle.localizedString(forKey: key, value: key, table: nil)
    return value == key ? nil : value
  }
}
