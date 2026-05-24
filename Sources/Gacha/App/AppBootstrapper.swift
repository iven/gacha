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

    let environment = AppEnvironment(
      directories: directories,
      settingsStore: settingsStore,
      memoryCardRepository: memoryCardRepository,
      launchAtLoginController: launchAtLoginController,
      menuBarController: MenuBarController(
        actions: MenuBarActions(
          openCards: {
            windowCoordinator.openCards()
          },
          openSettings: {
            windowCoordinator.openSettings()
          },
          setPaused: { _ in },
          quit: {
            NSApp.terminate(nil)
          })),
      windowCoordinator: windowCoordinator,
      presentationController: PresentationController(),
      suppressionController: SuppressionController())
    try environment.start()
    return environment
  }
}
