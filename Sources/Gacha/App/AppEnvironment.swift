import AppKit

@MainActor
final class AppEnvironment {
  let directories: AppDirectories
  let settingsStore: SettingsStore
  let memoryCardRepository: MemoryCardRepository
  let launchAtLoginController: LaunchAtLoginController
  let windowCoordinator: WindowCoordinator
  let notchController: NotchController
  let memoryNotchPresenter: MemoryNotchPresenter
  let suppressionController: SuppressionController
  let storageRelocationCoordinator: StorageRelocationCoordinator

  init(
    directories: AppDirectories,
    settingsStore: SettingsStore,
    memoryCardRepository: MemoryCardRepository,
    launchAtLoginController: LaunchAtLoginController,
    windowCoordinator: WindowCoordinator,
    notchController: NotchController,
    memoryNotchPresenter: MemoryNotchPresenter,
    suppressionController: SuppressionController,
    storageRelocationCoordinator: StorageRelocationCoordinator
  ) {
    self.directories = directories
    self.settingsStore = settingsStore
    self.memoryCardRepository = memoryCardRepository
    self.launchAtLoginController = launchAtLoginController
    self.windowCoordinator = windowCoordinator
    self.notchController = notchController
    self.memoryNotchPresenter = memoryNotchPresenter
    self.suppressionController = suppressionController
    self.storageRelocationCoordinator = storageRelocationCoordinator
  }

  func start() throws {
    do {
      try launchAtLoginController.synchronize(enabled: settingsStore.launchAtLoginEnabled)
    } catch {
      AppLogger.app.warning("Failed to synchronize launch at login: \(error.localizedDescription)")
    }

    try directories.prepareRoot()
    try memoryCardRepository.prepareStorage()
    try memoryCardRepository.rebuildIndex()

    suppressionController.start()
    let presenter = memoryNotchPresenter
    let schedule = notchController.autoCollapseSchedule
    notchController.start(
      expanded: {
        MemoryNotchExpandedView(presenter: presenter, autoCollapseSchedule: schedule)
      },
      compactLeading: { LogoCompactView() })
    memoryNotchPresenter.start()
  }

  // Bridges the SwiftUI Settings scene's lifecycle into AppKit-level effects:
  // accessory apps need to flip activation policy so the window comes forward,
  // and the notch needs to know so it stops auto-collapsing while open.
  func onSettingsVisibilityChange(_ visible: Bool) {
    if visible {
      NSApp.setActivationPolicy(.regular)
      NSApp.activate(ignoringOtherApps: true)
    }
    windowCoordinator.setSettingsVisible(visible)
  }
}
