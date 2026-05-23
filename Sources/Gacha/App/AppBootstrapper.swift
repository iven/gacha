import AppKit

@MainActor
struct AppBootstrapper {
  func bootstrap(fileManager: FileManager = .default) -> AppEnvironment {
    let settingsStore = SettingsStore(
      defaultUserStorageURL: SettingsStore.defaultUserStorageURL(fileManager: fileManager))
    let directories = AppDirectories(settingsStore: settingsStore, fileManager: fileManager)
    let windowCoordinator = WindowCoordinator(
      directories: directories,
      settingsStore: settingsStore)

    let environment = AppEnvironment(
      directories: directories,
      settingsStore: settingsStore,
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
