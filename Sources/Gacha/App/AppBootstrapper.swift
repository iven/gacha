import AppKit

@MainActor
struct AppBootstrapper {
  func bootstrap(fileManager: FileManager = .default) throws -> AppEnvironment {
    let settingsStore = SettingsStore(
      defaultUserStorageURL: SettingsStore.defaultUserStorageURL(fileManager: fileManager))
    let directories = AppDirectories(settingsStore: settingsStore, fileManager: fileManager)
    let memoryCardRepository = try MemoryCardRepository(
      directories: directories,
      fileManager: fileManager)

    let launchAtLoginController = LaunchAtLoginController()
    let windowCoordinator = WindowCoordinator(
      directories: directories,
      launchAtLoginController: launchAtLoginController,
      memoryCardRepository: memoryCardRepository,
      settingsStore: settingsStore)

    let notchController = NotchController(
      memoryCardRepository: memoryCardRepository,
      settingsStore: settingsStore)
    notchController.onNewCardRequested = {
      windowCoordinator.openCards()
    }
    notchController.onEditCardRequested = { card in
      windowCoordinator.openCards(editing: card)
    }
    notchController.onSettingsRequested = {
      windowCoordinator.openSettings()
    }

    let menuBarController = MenuBarController(
      actions: MenuBarActions(
        openCards: {
          windowCoordinator.openCards()
        },
        openSettings: {
          windowCoordinator.openSettings()
        },
        setPaused: { paused in
          notchController.setPaused(paused)
        },
        quit: {
          NSApp.terminate(nil)
        }))
    notchController.onPausedChange = { [weak menuBarController] paused in
      menuBarController?.setPaused(paused)
    }

    let environment = AppEnvironment(
      directories: directories,
      settingsStore: settingsStore,
      memoryCardRepository: memoryCardRepository,
      launchAtLoginController: launchAtLoginController,
      menuBarController: menuBarController,
      windowCoordinator: windowCoordinator,
      notchController: notchController,
      suppressionController: SuppressionController())
    try environment.start()
    return environment
  }
}
