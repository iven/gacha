import Foundation

// MARK: - Localization

func CLILocalized(_ key: String) -> String {
  let bundle = Bundle.module
  let preferences = Locale.preferredLanguages
  let localizations =
    CFBundleCopyLocalizationsForPreferences(
      bundle.localizations as CFArray,
      preferences as CFArray
    ) as? [String] ?? []

  for localization in localizations {
    guard
      let url = bundle.url(forResource: localization, withExtension: "lproj"),
      let lproj = Bundle(url: url)
    else { continue }
    let value = lproj.localizedString(forKey: key, value: key, table: nil)
    if value != key { return value }
  }

  return bundle.localizedString(forKey: key, value: key, table: nil)
}
