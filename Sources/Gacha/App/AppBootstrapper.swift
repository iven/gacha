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

    let suppressionController = SuppressionController(sources: [
      SuppressionController.Source(
        probe: FullScreenSpaceDetector(),
        isEnabled: { settingsStore.fullScreenSuppressionEnabled }),
      SuppressionController.Source(
        probe: ScreenCaptureDetector(),
        isEnabled: { settingsStore.screenSharingSuppressionEnabled }),
    ])
    suppressionController.onChange = { [weak notchController] suppressed in
      notchController?.setSuppressed(suppressed)
    }

    let storageRelocationCoordinator = StorageRelocationCoordinator(
      relocator: StorageRelocator(settingsStore: settingsStore, fileManager: fileManager),
      settingsStore: settingsStore,
      cardCount: { [weak memoryCardRepository] in
        (try? memoryCardRepository?.count()) ?? 0
      })

    let cardMCPServer = CardMCPServer(repository: memoryCardRepository)

    let environment = AppEnvironment(
      directories: directories,
      settingsStore: settingsStore,
      memoryCardRepository: memoryCardRepository,
      launchAtLoginController: launchAtLoginController,
      cardWindowBridge: cardWindowBridge,
      notchController: notchController,
      memoryNotchPresenter: presenter,
      suppressionController: suppressionController,
      storageRelocationCoordinator: storageRelocationCoordinator,
      cardMCPServer: cardMCPServer)
    try environment.start()
    return environment
  }
}
