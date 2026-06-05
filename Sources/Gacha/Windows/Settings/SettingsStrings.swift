import Foundation

enum SettingsStrings {
  static let windowTitle = AppStrings.localized("settings.window.title")
  static let sectionStartup = AppStrings.localized("settings.section.startup")
  static let sectionStorage = AppStrings.localized("settings.section.storage")
  static let sectionNotch = AppStrings.localized("settings.section.notch")
  static let sectionSuppression = AppStrings.localized("settings.section.suppression")
  static let sectionShortcuts = AppStrings.localized("settings.section.shortcuts")
  static let shortcutToggleNotch = AppStrings.localized("settings.shortcut.toggleNotch")
  static let storageLocation = AppStrings.localized("settings.storageLocation")
  static let storageLocationMove = AppStrings.localized("settings.storageLocation.move")
  static let storageLocationAdopt = AppStrings.localized("settings.storageLocation.adopt")
  static let storageOpenPanelTitle = AppStrings.localized(
    "settings.storageLocation.openPanel.title")
  static let storageOpenPanelPrompt = AppStrings.localized(
    "settings.storageLocation.openPanel.prompt")
  static let launchAtLogin = AppStrings.localized("settings.launchAtLogin")
  static let showKeyboardHints = AppStrings.localized("settings.showKeyboardHints")
  static let skipCountdownOnAnotherWindow = AppStrings.localized(
    "settings.skipCountdownOnAnotherWindow")
  static let fullScreenSuppressionEnabled = AppStrings.localized(
    "settings.fullScreenSuppressionEnabled")
  static let screenSharingSuppressionEnabled = AppStrings.localized(
    "settings.screenSharingSuppressionEnabled")
  static let focusModeSuppressionEnabled = AppStrings.localized(
    "settings.focusModeSuppressionEnabled")
  static let focusModeSuppressionHint = AppStrings.localized(
    "settings.focusModeSuppressionEnabled.hint")
  static let memoryCardCollapseCountdown = AppStrings.localized(
    "settings.memoryCardCollapseCountdown")
  static let memoryCardCollapseCountdownUnit = AppStrings.localized(
    "settings.memoryCardCollapseCountdown.unit")
  static let sectionMCP = AppStrings.localized("settings.section.mcp")
  static let mcpEnabled = AppStrings.localized("settings.mcp.enabled")
  static let mcpPort = AppStrings.localized("settings.mcp.port")
  static let mcpURLLabel = AppStrings.localized("settings.mcp.url")
  static let mcpPortApply = AppStrings.localized("settings.mcp.port.apply")
  static let mcpCopyURL = AppStrings.localized("settings.mcp.copyURL")
  static let mcpCopyConfig = AppStrings.localized("settings.mcp.copyConfig")
  static let mcpPortErrorTitle = AppStrings.localized("settings.mcp.port.error.title")
  static let mcpPortErrorDismiss = AppStrings.localized("settings.mcp.port.error.dismiss")
  static func mcpPortErrorFailed(port: Int, reason: String) -> String {
    String(
      format: AppStrings.localized("settings.mcp.port.error.failed"),
      port, reason)
  }

  static let sectionCLI = AppStrings.localized("settings.section.cli")
  static let cliInstall = AppStrings.localized("settings.cli.install")
  static let cliInstallAlreadyLatest = AppStrings.localized("settings.cli.install.alreadyLatest")
  static let cliInstallConflict = AppStrings.localized("settings.cli.install.conflict")
  static let cliInstallSuccess = AppStrings.localized("settings.cli.install.success")
  static let cliInstallRequiresMCP = AppStrings.localized("settings.cli.install.requiresMCP")
  static let cliInstallInstalled = AppStrings.localized("settings.cli.install.installed")
  static let quitApp = AppStrings.localized("settings.quitApp")
  static func cliInstallFailed(reason: String) -> String {
    String(format: AppStrings.localized("settings.cli.install.failed"), reason)
  }
}
