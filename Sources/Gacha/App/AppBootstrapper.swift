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

    let notchController = NotchController()
    let presenter = MemoryNotchPresenter(
      controller: notchController,
      memoryCardRepository: memoryCardRepository,
      settingsStore: settingsStore)
    presenter.onNewCardRequested = {
      windowCoordinator.openCards()
    }
    presenter.onEditCardRequested = { card in
      windowCoordinator.openCards(editing: card)
    }
    presenter.onSettingsRequested = {
      windowCoordinator.openSettings()
    }

    notchController.onResumeRequested = { [weak notchController] in
      notchController?.setPaused(false)
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

    windowCoordinator.onPreviewCardChange = { [weak presenter] card in
      presenter?.setPreviewCard(card)
    }

    let environment = AppEnvironment(
      directories: directories,
      settingsStore: settingsStore,
      memoryCardRepository: memoryCardRepository,
      launchAtLoginController: launchAtLoginController,
      menuBarController: menuBarController,
      windowCoordinator: windowCoordinator,
      notchController: notchController,
      memoryNotchPresenter: presenter,
      suppressionController: SuppressionController())
    try environment.start()
    return environment
  }
}
