import Foundation

enum SettingsStrings {
  static let windowTitle = AppStrings.localized("settings.window.title")
  static let tabGeneral = AppStrings.localized("settings.tab.general")
  static let tabIntegrations = AppStrings.localized("settings.tab.integrations")
  static let tabAdvanced = AppStrings.localized("settings.tab.advanced")
  static let tabAbout = AppStrings.localized("settings.tab.about")
  static let sectionStartup = AppStrings.localized("settings.section.startup")
  static let sectionStorage = AppStrings.localized("settings.section.storage")
  static let sectionGeneral = AppStrings.localized("settings.section.general")
  static let sectionNotch = AppStrings.localized("settings.section.notch")
  static let sectionMemoryCards = AppStrings.localized("settings.section.memoryCards")
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
  static let collapseCountdown = AppStrings.localized("settings.collapseCountdown")
  static let collapseCountdownUnit = AppStrings.localized("settings.collapseCountdown.unit")
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
  static let advancedQuitApp = AppStrings.localized("settings.advanced.quitApp")
  static func aboutVersion(_ version: String) -> String {
    String(format: AppStrings.localized("settings.about.version"), version)
  }
  static let aboutSlogan = AppStrings.localized("settings.about.slogan")
  static let aboutCopyright = AppStrings.localized("settings.about.copyright")
  static let aboutCopyrightLine1 = AppStrings.localized("settings.about.copyright.line1")
  static let aboutCopyrightLine2 = AppStrings.localized("settings.about.copyright.line2")
  static func cliInstallFailed(reason: String) -> String {
    String(format: AppStrings.localized("settings.cli.install.failed"), reason)
  }
}
