import Foundation

enum AppMetadata {
  static let name = "Gacha"
  static let bundleIdentifier = "com.iven.gacha"
  static let applicationSupportDirectoryName = "Gacha"
  static let userStorageDirectoryName = "Gacha"
  static let memoryDirectoryName = "memory"
  static let defaultCategoryDirectoryName = "Uncategorized"
  // Empty marker file written into a Gacha storage root. Its presence is the
  // sole signal used when adopting a directory during relocation.
  static let storageRootMarkerName = ".gacha"

  /// Human-readable version string. Falls back to placeholders when bundle
  /// keys are missing (e.g. running via `swift run` without an Info.plist).
  static var version: String {
    let info = Bundle.main.infoDictionary
    let short = info?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    let build = info?["CFBundleVersion"] as? String ?? "0"
    return "\(short) (\(build))"
  }
}
