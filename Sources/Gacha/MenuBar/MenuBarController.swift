import AppKit

@MainActor
final class MenuBarController: NSObject {
  private let actions: MenuBarActions
  private var state = MenuBarState()
  private var statusItem: NSStatusItem?
  private var pauseItem: NSMenuItem?

  init(actions: MenuBarActions = .live) {
    self.actions = actions
  }

  func start() {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    statusItem.button?.title = AppMetadata.name
    statusItem.menu = makeMenu()
    self.statusItem = statusItem
  }

  private func makeMenu() -> NSMenu {
    let menu = NSMenu()

    let pauseItem = NSMenuItem(
      title: state.pauseDisplayTitle,
      action: #selector(togglePause),
      keyEquivalent: "")
    pauseItem.target = self
    menu.addItem(pauseItem)
    self.pauseItem = pauseItem

    let cardsItem = NSMenuItem(
      title: MenuBarStrings.cards,
      action: #selector(openCards),
      keyEquivalent: "")
    cardsItem.target = self
    menu.addItem(cardsItem)

    let settingsItem = NSMenuItem(
      title: MenuBarStrings.settings,
      action: #selector(openSettings),
      keyEquivalent: ",")
    settingsItem.target = self
    menu.addItem(settingsItem)

    menu.addItem(.separator())

    let quitItem = NSMenuItem(
      title: MenuBarStrings.quit,
      action: #selector(quit),
      keyEquivalent: "q")
    quitItem.target = self
    menu.addItem(quitItem)

    return menu
  }

  @objc private func openCards() {
    actions.openCards()
  }

  @objc private func openSettings() {
    actions.openSettings()
  }

  @objc private func togglePause() {
    state.isPaused.toggle()
    pauseItem?.title = state.pauseDisplayTitle
    actions.setPaused(state.isPaused)
  }

  @objc private func quit() {
    actions.quit()
  }
}
