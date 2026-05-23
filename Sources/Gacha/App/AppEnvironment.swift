import Foundation

@MainActor
final class AppEnvironment {
  let directories: AppDirectories
  let settingsStore: SettingsStore
  let launchAtLoginController: LaunchAtLoginController
  let menuBarController: MenuBarController
  let windowCoordinator: WindowCoordinator
  let presentationController: PresentationController
  let suppressionController: SuppressionController

  init(
    directories: AppDirectories,
    settingsStore: SettingsStore,
    launchAtLoginController: LaunchAtLoginController,
    menuBarController: MenuBarController,
    windowCoordinator: WindowCoordinator,
    presentationController: PresentationController,
    suppressionController: SuppressionController
  ) {
    self.directories = directories
    self.settingsStore = settingsStore
    self.launchAtLoginController = launchAtLoginController
    self.menuBarController = menuBarController
    self.windowCoordinator = windowCoordinator
    self.presentationController = presentationController
    self.suppressionController = suppressionController
  }

  func start() {
    do {
      try launchAtLoginController.synchronize(enabled: settingsStore.launchAtLoginEnabled)
    } catch {
      AppLogger.app.warning("Failed to synchronize launch at login: \(error.localizedDescription)")
    }

    suppressionController.start()
    presentationController.start()
    menuBarController.start()
  }
}
