import Foundation

struct AppSettings: Equatable {
  var userStorageURL: URL
  var launchAtLoginEnabled: Bool
  var memoryAutoCollapseSeconds: TimeInterval
  var skipCountdownOnAnotherWindow: Bool
  var showKeyboardHints: Bool
  var fullScreenSuppressionEnabled: Bool
  var screenSharingSuppressionEnabled: Bool
  var focusModeSuppressionEnabled: Bool
  var mcpEnabled: Bool
  var mcpPort: Int

  static let defaultLaunchAtLoginEnabled = true
  static let defaultMemoryAutoCollapseSeconds: TimeInterval = 1
  static let defaultSkipCountdownOnAnotherWindow = true
  static let defaultShowKeyboardHints = true
  static let defaultFullScreenSuppressionEnabled = true
  static let defaultScreenSharingSuppressionEnabled = true
  static let defaultFocusModeSuppressionEnabled = true
  static let defaultMCPEnabled = false
  static let defaultMCPPort = 7771

  static func defaults(userStorageURL: URL) -> AppSettings {
    AppSettings(
      userStorageURL: userStorageURL,
      launchAtLoginEnabled: defaultLaunchAtLoginEnabled,
      memoryAutoCollapseSeconds: defaultMemoryAutoCollapseSeconds,
      skipCountdownOnAnotherWindow: defaultSkipCountdownOnAnotherWindow,
      showKeyboardHints: defaultShowKeyboardHints,
      fullScreenSuppressionEnabled: defaultFullScreenSuppressionEnabled,
      screenSharingSuppressionEnabled: defaultScreenSharingSuppressionEnabled,
      focusModeSuppressionEnabled: defaultFocusModeSuppressionEnabled,
      mcpEnabled: defaultMCPEnabled,
      mcpPort: defaultMCPPort)
  }
}
