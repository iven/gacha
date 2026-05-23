import Foundation

@MainActor
final class AppEnvironment {
  let directories: AppDirectories
  let settingsStore: SettingsStore
  let menuBarController: MenuBarController
  let windowCoordinator: WindowCoordinator
  let presentationController: PresentationController
  let suppressionController: SuppressionController

  init(
    directories: AppDirectories,
    settingsStore: SettingsStore,
    menuBarController: MenuBarController,
    windowCoordinator: WindowCoordinator,
    presentationController: PresentationController,
    suppressionController: SuppressionController
  ) {
    self.directories = directories
    self.settingsStore = settingsStore
    self.menuBarController = menuBarController
    self.windowCoordinator = windowCoordinator
    self.presentationController = presentationController
    self.suppressionController = suppressionController
  }

  func start() {
    suppressionController.start()
    presentationController.start()
    menuBarController.start()
  }
}
