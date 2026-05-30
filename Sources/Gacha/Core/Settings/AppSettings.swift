import Foundation

struct AppSettings: Equatable {
  var userStorageURL: URL
  var launchAtLoginEnabled: Bool
  var memoryAutoCollapseSeconds: TimeInterval
  var skipCountdownOnAnotherWindow: Bool
  var showKeyboardHints: Bool
  var fullScreenSuppressionEnabled: Bool
  var screenSharingSuppressionEnabled: Bool

  static let defaultLaunchAtLoginEnabled = true
  static let defaultMemoryAutoCollapseSeconds: TimeInterval = 1
  static let defaultSkipCountdownOnAnotherWindow = true
  static let defaultShowKeyboardHints = true
  static let defaultFullScreenSuppressionEnabled = true
  static let defaultScreenSharingSuppressionEnabled = true

  static func defaults(userStorageURL: URL) -> AppSettings {
    AppSettings(
      userStorageURL: userStorageURL,
      launchAtLoginEnabled: defaultLaunchAtLoginEnabled,
      memoryAutoCollapseSeconds: defaultMemoryAutoCollapseSeconds,
      skipCountdownOnAnotherWindow: defaultSkipCountdownOnAnotherWindow,
      showKeyboardHints: defaultShowKeyboardHints,
      fullScreenSuppressionEnabled: defaultFullScreenSuppressionEnabled,
      screenSharingSuppressionEnabled: defaultScreenSharingSuppressionEnabled)
  }
}
