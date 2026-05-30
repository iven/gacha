import AppKit

@MainActor
struct AppBootstrapper {
  let windowOpenActionRegistry: WindowOpenActionRegistry

  init(windowOpenActionRegistry: WindowOpenActionRegistry = WindowOpenActionRegistry()) {
    self.windowOpenActionRegistry = windowOpenActionRegistry
  }

  func bootstrap(fileManager: FileManager = .default) throws -> AppEnvironment {
    let settingsStore = SettingsStore(
      defaultUserStorageURL: SettingsStore.defaultUserStorageURL(fileManager: fileManager))
    let directories = AppDirectories(settingsStore: settingsStore, fileManager: fileManager)
    let memoryCardRepository = try MemoryCardRepository(
      directories: directories,
      fileManager: fileManager)

    let launchAtLoginController = LaunchAtLoginController()
    let cardWindowBridge = CardWindowBridge(
      windowOpenActionRegistry: windowOpenActionRegistry)

    let notchController = NotchController()
    let presenter = MemoryNotchPresenter(
      controller: notchController,
      memoryCardRepository: memoryCardRepository,
      settingsStore: settingsStore,
      cardWindowBridge: cardWindowBridge)
    presenter.onPauseRequested = { [weak notchController] in
      notchController?.setPaused(true)
    }
    presenter.onSettingsRequested = {
      windowOpenActionRegistry.open(.settings)
    }

    notchController.onResumeRequested = { [weak notchController] in
      notchController?.setPaused(false)
    }

    let menuBarViewModel = AppDelegate.menuBarViewModel
    menuBarViewModel.onTogglePause = { [weak notchController] paused in
      notchController?.setPaused(paused)
    }
    notchController.onPausedChange = { [weak menuBarViewModel] paused in
      menuBarViewModel?.isPaused = paused
    }

    let storageRelocationCoordinator = StorageRelocationCoordinator(
      relocator: StorageRelocator(settingsStore: settingsStore, fileManager: fileManager),
      settingsStore: settingsStore,
      cardCount: { [weak memoryCardRepository] in
        (try? memoryCardRepository?.count()) ?? 0
      })

    let environment = AppEnvironment(
      directories: directories,
      settingsStore: settingsStore,
      memoryCardRepository: memoryCardRepository,
      launchAtLoginController: launchAtLoginController,
      cardWindowBridge: cardWindowBridge,
      notchController: notchController,
      memoryNotchPresenter: presenter,
      suppressionController: SuppressionController(),
      storageRelocationCoordinator: storageRelocationCoordinator)
    try environment.start()
    return environment
  }
}
