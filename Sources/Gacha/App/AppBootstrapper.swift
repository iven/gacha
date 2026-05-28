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
    let windowCoordinator = WindowCoordinator(memoryCardRepository: memoryCardRepository)

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
    presenter.onPauseRequested = { [weak notchController] in
      notchController?.setPaused(true)
    }

    notchController.onResumeRequested = { [weak notchController] in
      notchController?.setPaused(false)
    }

    let menuBarViewModel = AppDelegate.menuBarViewModel
    menuBarViewModel.onTogglePause = { [weak notchController] paused in
      notchController?.setPaused(paused)
    }
    menuBarViewModel.onOpenCards = {
      windowCoordinator.openCards()
    }
    notchController.onPausedChange = { [weak menuBarViewModel] paused in
      menuBarViewModel?.isPaused = paused
    }

    windowCoordinator.onPreviewCardChange = { [weak presenter] card in
      presenter?.setPreviewCard(card)
    }
    windowCoordinator.onManagedWindowVisibilityChange = { [weak presenter] visible in
      presenter?.setHasVisibleManagedWindow(visible)
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
      windowCoordinator: windowCoordinator,
      notchController: notchController,
      memoryNotchPresenter: presenter,
      suppressionController: SuppressionController(),
      storageRelocationCoordinator: storageRelocationCoordinator)
    try environment.start()
    return environment
  }
}
