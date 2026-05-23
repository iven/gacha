import Foundation

struct AppBootstrapper {
  func bootstrap(fileManager: FileManager = .default) -> AppEnvironment {
    let directories = AppDirectories(fileManager: fileManager)
    let settingsStore = SettingsStore(settingsURL: directories.settingsURL)

    let environment = AppEnvironment(
      directories: directories,
      settingsStore: settingsStore,
      menuBarController: MenuBarController(),
      windowCoordinator: WindowCoordinator(),
      presentationController: PresentationController(),
      suppressionController: SuppressionController())
    environment.start()
    return environment
  }
}
