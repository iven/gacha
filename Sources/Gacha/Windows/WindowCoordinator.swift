import AppKit

@MainActor
final class WindowCoordinator {
  private let cardManagement: CardManagementWindowController
  private let settings: SettingsWindowController

  init(
    directories: AppDirectories,
    launchAtLoginController: LaunchAtLoginController,
    memoryCardRepository: MemoryCardRepository,
    settingsStore: SettingsStore
  ) {
    cardManagement = CardManagementWindowController(
      memoryCardRepository: memoryCardRepository)
    settings = SettingsWindowController(
      directories: directories,
      launchAtLoginController: launchAtLoginController,
      settingsStore: settingsStore)

    cardManagement.onWindowDidClose = { [weak self] in
      self?.refreshActivationPolicy()
    }
    settings.onWindowDidClose = { [weak self] in
      self?.refreshActivationPolicy()
    }
  }

  func openCards(editing card: MemoryCard? = nil) {
    NSApp.setActivationPolicy(.regular)
    cardManagement.show(editing: card)
    NSApp.activate(ignoringOtherApps: true)
  }

  func openSettings() {
    NSApp.setActivationPolicy(.regular)
    settings.show()
    NSApp.activate(ignoringOtherApps: true)
  }

  private func refreshActivationPolicy() {
    if !hasVisibleManagedWindow {
      NSApp.setActivationPolicy(.accessory)
    }
  }

  private var hasVisibleManagedWindow: Bool {
    [cardManagement.window, settings.window].contains { $0?.isVisible == true }
  }
}
