import AppKit

@MainActor
final class WindowCoordinator {
  var onPreviewCardChange: ((MemoryCard?) -> Void)? {
    didSet {
      cardManagement.onPreviewCardChange = onPreviewCardChange
    }
  }
  var onManagedWindowVisibilityChange: ((Bool) -> Void)?

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
      self?.handleManagedWindowVisibilityChange()
    }
    settings.onWindowDidClose = { [weak self] in
      self?.handleManagedWindowVisibilityChange()
    }
  }

  func openCards(editing card: MemoryCard? = nil) {
    NSApp.setActivationPolicy(.regular)
    cardManagement.show(editing: card)
    NSApp.activate(ignoringOtherApps: true)
    handleManagedWindowVisibilityChange()
  }

  func openSettings() {
    NSApp.setActivationPolicy(.regular)
    settings.show()
    NSApp.activate(ignoringOtherApps: true)
    handleManagedWindowVisibilityChange()
  }

  private func handleManagedWindowVisibilityChange() {
    refreshActivationPolicy()
    onManagedWindowVisibilityChange?(hasVisibleManagedWindow)
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
