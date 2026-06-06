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
    let noticeQueue = NoticeQueue()

    let launchAtLoginController = LaunchAtLoginController()
    let cardWindowBridge = CardWindowBridge(
      windowOpenActionRegistry: windowOpenActionRegistry)

    let notchController = NotchController()
    let presenter = MemoryNotchPresenter(
      memoryCardRepository: memoryCardRepository,
      settingsStore: settingsStore,
      cardWindowBridge: cardWindowBridge)
    let notchPresentationCoordinator = NotchPresentationCoordinator(
      controller: notchController,
      memoryPresenter: presenter)
    presenter.onSettingsRequested = {
      windowOpenActionRegistry.open(.settings)
    }

    let suppressionController = SuppressionController(sources: [
      SuppressionController.Source(
        probe: FullScreenSpaceDetector(),
        isEnabled: { settingsStore.fullScreenSuppressionEnabled }),
      SuppressionController.Source(
        probe: ScreenCaptureDetector(),
        isEnabled: { settingsStore.screenSharingSuppressionEnabled }),
      SuppressionController.Source(
        probe: FocusModeDetector(),
        isEnabled: { settingsStore.focusModeSuppressionEnabled }),
    ])
    suppressionController.onChange = { [weak notchPresentationCoordinator] suppressed in
      notchPresentationCoordinator?.setSuppressed(suppressed)
    }

    let storageRelocationCoordinator = StorageRelocationCoordinator(
      relocator: StorageRelocator(settingsStore: settingsStore, fileManager: fileManager),
      settingsStore: settingsStore,
      cardCount: { [weak memoryCardRepository] in
        (try? memoryCardRepository?.count()) ?? 0
      })

    let gachaMCPServer = GachaMCPServer(
      repository: memoryCardRepository,
      noticeQueue: noticeQueue)

    let environment = AppEnvironment(
      directories: directories,
      settingsStore: settingsStore,
      memoryCardRepository: memoryCardRepository,
      noticeQueue: noticeQueue,
      launchAtLoginController: launchAtLoginController,
      cardWindowBridge: cardWindowBridge,
      notchPresentationCoordinator: notchPresentationCoordinator,
      suppressionController: suppressionController,
      storageRelocationCoordinator: storageRelocationCoordinator,
      gachaMCPServer: gachaMCPServer)
    try environment.start()
    return environment
  }
}
