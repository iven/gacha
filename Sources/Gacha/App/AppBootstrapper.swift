import AppKit

@MainActor
struct AppBootstrapper {
  func bootstrap(fileManager: FileManager = .default) -> AppEnvironment {
    let settingsStore = SettingsStore(
      defaultUserStorageURL: SettingsStore.defaultUserStorageURL(fileManager: fileManager))
    let directories = AppDirectories(settingsStore: settingsStore, fileManager: fileManager)
    do {
      try MemoryCardFileRepository(
        directories: directories,
        fileManager: fileManager
      ).prepareStorage()
    } catch {
      AppLogger.app.error("Failed to prepare app directories: \(error.localizedDescription)")
    }

    let launchAtLoginController = LaunchAtLoginController()
    let windowCoordinator = WindowCoordinator(
      directories: directories,
      launchAtLoginController: launchAtLoginController,
      settingsStore: settingsStore)

    let environment = AppEnvironment(
      directories: directories,
      settingsStore: settingsStore,
      launchAtLoginController: launchAtLoginController,
      menuBarController: MenuBarController(
        actions: MenuBarActions(
          openNewCard: {},
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
    environment.start()
    return environment
  }
}
