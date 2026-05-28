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
  private var settingsWindowVisible = false

  init(memoryCardRepository: MemoryCardRepository) {
    cardManagement = CardManagementWindowController(
      memoryCardRepository: memoryCardRepository)

    cardManagement.onWindowDidClose = { [weak self] in
      self?.handleManagedWindowVisibilityChange()
    }
  }

  func openCards(editing card: MemoryCard? = nil) {
    NSApp.setActivationPolicy(.regular)
    cardManagement.show(editing: card)
    NSApp.activate(ignoringOtherApps: true)
    handleManagedWindowVisibilityChange()
  }

  // Called by SettingsView's onAppear/onDisappear so the notch can suppress its
  // auto-collapse while the settings window is open.
  func setSettingsVisible(_ visible: Bool) {
    guard settingsWindowVisible != visible else { return }
    settingsWindowVisible = visible
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
    cardManagement.window?.isVisible == true || settingsWindowVisible
  }
}
