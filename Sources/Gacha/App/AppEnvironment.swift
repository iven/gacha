import Foundation

@MainActor
final class AppEnvironment {
  let directories: AppDirectories
  let settingsStore: SettingsStore
  let memoryCardRepository: MemoryCardRepository
  let launchAtLoginController: LaunchAtLoginController
  let menuBarController: MenuBarController
  let windowCoordinator: WindowCoordinator
  let notchController: NotchController
  let memoryNotchPresenter: MemoryNotchPresenter
  let suppressionController: SuppressionController

  init(
    directories: AppDirectories,
    settingsStore: SettingsStore,
    memoryCardRepository: MemoryCardRepository,
    launchAtLoginController: LaunchAtLoginController,
    menuBarController: MenuBarController,
    windowCoordinator: WindowCoordinator,
    notchController: NotchController,
    memoryNotchPresenter: MemoryNotchPresenter,
    suppressionController: SuppressionController
  ) {
    self.directories = directories
    self.settingsStore = settingsStore
    self.memoryCardRepository = memoryCardRepository
    self.launchAtLoginController = launchAtLoginController
    self.menuBarController = menuBarController
    self.windowCoordinator = windowCoordinator
    self.notchController = notchController
    self.memoryNotchPresenter = memoryNotchPresenter
    self.suppressionController = suppressionController
  }

  func start() throws {
    do {
      try launchAtLoginController.synchronize(enabled: settingsStore.launchAtLoginEnabled)
    } catch {
      AppLogger.app.warning("Failed to synchronize launch at login: \(error.localizedDescription)")
    }

    try memoryCardRepository.prepareStorage()
    try memoryCardRepository.rebuildIndex()

    suppressionController.start()
    let presenter = memoryNotchPresenter
    notchController.start(
      expanded: { MemoryNotchExpandedView(presenter: presenter) },
      compactLeading: { LogoCompactView() })
    memoryNotchPresenter.start()
    menuBarController.start()
  }
}
