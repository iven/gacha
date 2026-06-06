import AppKit
import Combine
import Foundation
import KeyboardShortcuts

@MainActor
final class AppEnvironment: ObservableObject {
  let directories: AppDirectories
  let settingsStore: SettingsStore
  let memoryCardRepository: MemoryCardRepository
  let noticeQueue: NoticeQueue
  let launchAtLoginController: LaunchAtLoginController
  let cardWindowBridge: CardWindowBridge
  let notchPresentationCoordinator: NotchPresentationCoordinator
  let suppressionController: SuppressionController
  let storageRelocationCoordinator: StorageRelocationCoordinator
  let gachaMCPServer: GachaMCPServer
  @Published private(set) var isMCPServerRunning = false

  /// Single card-management model shared by the single-instance card window.
  private(set) lazy var cardManagementModel = CardManagementModel(
    memoryCardRepository: memoryCardRepository,
    cardWindowBridge: cardWindowBridge)

  init(
    directories: AppDirectories,
    settingsStore: SettingsStore,
    memoryCardRepository: MemoryCardRepository,
    noticeQueue: NoticeQueue,
    launchAtLoginController: LaunchAtLoginController,
    cardWindowBridge: CardWindowBridge,
    notchPresentationCoordinator: NotchPresentationCoordinator,
    suppressionController: SuppressionController,
    storageRelocationCoordinator: StorageRelocationCoordinator,
    gachaMCPServer: GachaMCPServer
  ) {
    self.directories = directories
    self.settingsStore = settingsStore
    self.memoryCardRepository = memoryCardRepository
    self.noticeQueue = noticeQueue
    self.launchAtLoginController = launchAtLoginController
    self.cardWindowBridge = cardWindowBridge
    self.notchPresentationCoordinator = notchPresentationCoordinator
    self.suppressionController = suppressionController
    self.storageRelocationCoordinator = storageRelocationCoordinator
    self.gachaMCPServer = gachaMCPServer
  }

  func start() throws {
    do {
      try launchAtLoginController.synchronize(enabled: settingsStore.launchAtLoginEnabled)
    } catch {
      AppLogger.app.warning("Failed to synchronize launch at login: \(error.localizedDescription)")
    }

    try directories.prepareRoot()
    try memoryCardRepository.prepareStorage()
    try memoryCardRepository.rebuildIndex()

    suppressionController.start()
    notchPresentationCoordinator.start()

    let coordinatorRef = notchPresentationCoordinator
    KeyboardShortcuts.onKeyDown(for: .toggleNotch) { [weak coordinatorRef] in
      coordinatorRef?.handleToggleShortcut()
    }

    let server = gachaMCPServer
    let store = settingsStore
    Task {
      guard store.mcpEnabled else { return }
      do {
        try await server.start(port: store.mcpPort)
        isMCPServerRunning = true
      } catch {
        AppLogger.app.error("Failed to start MCP server: \(error.localizedDescription)")
      }
    }
  }

  func applyMCPSettings(enabled: Bool, port: Int) async throws {
    if enabled {
      try await gachaMCPServer.restart(port: port)
      settingsStore.mcpEnabled = true
      settingsStore.mcpPort = port
    } else {
      await gachaMCPServer.stop()
      settingsStore.mcpEnabled = false
    }
    isMCPServerRunning = gachaMCPServer.isRunning
  }

  // Bridges the SwiftUI Settings scene's lifecycle into the shared window
  // bridge, which flips activation policy (accessory apps need .regular to come
  // forward) and tells the notch to stop auto-collapsing while a window is open.
  func onSettingsVisibilityChange(_ visible: Bool) {
    cardWindowBridge.setSettingsVisible(visible)
  }

  private func resolveCLIBinaryURL() -> URL? {
    guard let bundleURL = Bundle.main.executableURL?.deletingLastPathComponent() else {
      return nil
    }
    let entries = (try? FileManager.default.contentsOfDirectory(atPath: bundleURL.path)) ?? []
    guard entries.contains("gacha-cli") else { return nil }
    return bundleURL.appendingPathComponent("gacha-cli")
  }

  func isCLIInstalled() -> Bool {
    guard let cliBinaryURL = resolveCLIBinaryURL() else { return false }
    let linkURL = URL(fileURLWithPath: "/usr/local/bin/gacha")
    let existing = try? FileManager.default.destinationOfSymbolicLink(atPath: linkURL.path)
    return existing == cliBinaryURL.path
  }

  // MARK: - CLI Installation

  enum CLIInstallResult {
    case alreadyLatest
    case conflict
    case success
  }

  func installCLI() async throws -> CLIInstallResult {
    guard let cliBinaryURL = resolveCLIBinaryURL() else {
      throw CLIInstallError.binaryNotFound
    }

    let linkURL = URL(fileURLWithPath: "/usr/local/bin/gacha")
    let binDirURL = linkURL.deletingLastPathComponent()

    // Already points to same binary — skip
    if let existing = try? FileManager.default.destinationOfSymbolicLink(
      atPath: linkURL.path),
      existing == cliBinaryURL.path
    {
      return .alreadyLatest
    }

    // Exists but points elsewhere — conflict
    if FileManager.default.fileExists(atPath: linkURL.path) {
      return .conflict
    }

    // Try without privileges first
    if (try? FileManager.default.createSymbolicLink(
      at: linkURL, withDestinationURL: cliBinaryURL)) != nil
    {
      return .success
    }

    // Escalate via NSAppleScript
    let cmd = "mkdir -p '\(binDirURL.path)' && ln -sf '\(cliBinaryURL.path)' '\(linkURL.path)'"
    let script = "do shell script \"\(cmd)\" with administrator privileges"
    var error: NSDictionary?
    NSAppleScript(source: script)?.executeAndReturnError(&error)
    if error != nil {
      throw CLIInstallError.osascriptFailed
    }
    return .success
  }
}

// MARK: - CLIInstallError

private enum CLIInstallError: LocalizedError {
  case binaryNotFound
  case osascriptFailed

  var errorDescription: String? {
    switch self {
    case .binaryNotFound:
      return AppStrings.localized("settings.cli.install.error.binaryNotFound")
    case .osascriptFailed:
      return AppStrings.localized("settings.cli.install.error.cancelled")
    }
  }
}
