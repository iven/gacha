import Foundation

struct AppSettings: Equatable {
  var userStorageURL: URL
  var launchAtLoginEnabled: Bool
  var memoryCardAutoCollapseSeconds: TimeInterval
  var noticeAutoCollapseSeconds: TimeInterval
  var idleReminderAnimationSeconds: TimeInterval
  var skipAutoCollapseOnAnotherWindow: Bool
  var showKeyboardHints: Bool
  var fullScreenSuppressionEnabled: Bool
  var screenSharingSuppressionEnabled: Bool
  var focusModeSuppressionEnabled: Bool
  var mcpEnabled: Bool
  var mcpPort: Int

  static let defaultLaunchAtLoginEnabled = true
  static let defaultMemoryCardAutoCollapseSeconds: TimeInterval = 1
  static let defaultNoticeAutoCollapseSeconds: TimeInterval = 1
  static let defaultIdleReminderAnimationSeconds: TimeInterval = 30 * 60
  static let defaultSkipAutoCollapseOnAnotherWindow = true
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
      memoryCardAutoCollapseSeconds: defaultMemoryCardAutoCollapseSeconds,
      noticeAutoCollapseSeconds: defaultNoticeAutoCollapseSeconds,
      idleReminderAnimationSeconds: defaultIdleReminderAnimationSeconds,
      skipAutoCollapseOnAnotherWindow: defaultSkipAutoCollapseOnAnotherWindow,
      showKeyboardHints: defaultShowKeyboardHints,
      fullScreenSuppressionEnabled: defaultFullScreenSuppressionEnabled,
      screenSharingSuppressionEnabled: defaultScreenSharingSuppressionEnabled,
      focusModeSuppressionEnabled: defaultFocusModeSuppressionEnabled,
      mcpEnabled: defaultMCPEnabled,
      mcpPort: defaultMCPPort)
  }
}
