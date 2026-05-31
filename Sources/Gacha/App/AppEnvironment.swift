import AppKit
import Combine

@MainActor
final class AppEnvironment: ObservableObject {
  let directories: AppDirectories
  let settingsStore: SettingsStore
  let memoryCardRepository: MemoryCardRepository
  let launchAtLoginController: LaunchAtLoginController
  let cardWindowBridge: CardWindowBridge
  let notchController: NotchController
  let memoryNotchPresenter: MemoryNotchPresenter
  let suppressionController: SuppressionController
  let storageRelocationCoordinator: StorageRelocationCoordinator
  let cardMCPServer: CardMCPServer
  @Published private(set) var isMCPServerRunning = false

  /// Single card-management model shared by the single-instance card window.
  private(set) lazy var cardManagementModel = CardManagementModel(
    memoryCardRepository: memoryCardRepository)

  init(
    directories: AppDirectories,
    settingsStore: SettingsStore,
    memoryCardRepository: MemoryCardRepository,
    launchAtLoginController: LaunchAtLoginController,
    cardWindowBridge: CardWindowBridge,
    notchController: NotchController,
    memoryNotchPresenter: MemoryNotchPresenter,
    suppressionController: SuppressionController,
    storageRelocationCoordinator: StorageRelocationCoordinator,
    cardMCPServer: CardMCPServer
  ) {
    self.directories = directories
    self.settingsStore = settingsStore
    self.memoryCardRepository = memoryCardRepository
    self.launchAtLoginController = launchAtLoginController
    self.cardWindowBridge = cardWindowBridge
    self.notchController = notchController
    self.memoryNotchPresenter = memoryNotchPresenter
    self.suppressionController = suppressionController
    self.storageRelocationCoordinator = storageRelocationCoordinator
    self.cardMCPServer = cardMCPServer
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
    let presenter = memoryNotchPresenter
    let schedule = notchController.autoCollapseSchedule
    notchController.start(
      expanded: {
        MemoryNotchExpandedView(presenter: presenter, autoCollapseSchedule: schedule)
      },
      compactLeading: { LogoCompactView() })
    memoryNotchPresenter.start()

    let server = cardMCPServer
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
      try await cardMCPServer.restart(port: port)
      settingsStore.mcpEnabled = true
      settingsStore.mcpPort = port
    } else {
      await cardMCPServer.stop()
      settingsStore.mcpEnabled = false
    }
    isMCPServerRunning = cardMCPServer.isRunning
  }

  // Bridges the SwiftUI Settings scene's lifecycle into the shared window
  // bridge, which flips activation policy (accessory apps need .regular to come
  // forward) and tells the notch to stop auto-collapsing while a window is open.
  func onSettingsVisibilityChange(_ visible: Bool) {
    cardWindowBridge.setSettingsVisible(visible)
  }
}
