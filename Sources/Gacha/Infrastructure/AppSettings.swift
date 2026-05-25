import Foundation

struct AppSettings: Equatable {
  var userStorageURL: URL
  var launchAtLoginEnabled: Bool
  var memoryAutoCollapseSeconds: TimeInterval

  static let defaultLaunchAtLoginEnabled = true
  static let defaultMemoryAutoCollapseSeconds: TimeInterval = 30

  static func defaults(userStorageURL: URL) -> AppSettings {
    AppSettings(
      userStorageURL: userStorageURL,
      launchAtLoginEnabled: defaultLaunchAtLoginEnabled,
      memoryAutoCollapseSeconds: defaultMemoryAutoCollapseSeconds)
  }
}
