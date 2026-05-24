import AppKit
import SwiftUI

@MainActor
final class WindowCoordinator: NSObject, NSWindowDelegate {
  private static let cardManagementDefaultContentSize = NSSize(width: 960, height: 720)

  private let directories: AppDirectories
  private let launchAtLoginController: LaunchAtLoginController
  private let memoryCardRepository: MemoryCardRepository
  private let settingsStore: SettingsStore
  private weak var cardManagementViewController: CardManagementSplitViewController?
  private weak var cardManagementSplitView: NSSplitView?
  private var cardManagementWindow: NSWindow?
  private var settingsWindow: NSWindow?

  init(
    directories: AppDirectories,
    launchAtLoginController: LaunchAtLoginController,
    memoryCardRepository: MemoryCardRepository,
    settingsStore: SettingsStore
  ) {
    self.directories = directories
    self.launchAtLoginController = launchAtLoginController
    self.memoryCardRepository = memoryCardRepository
    self.settingsStore = settingsStore
    super.init()
  }

  func openCards() {
    NSApp.setActivationPolicy(.regular)
    let window = cardManagementWindow ?? makeCardManagementWindow()
    cardManagementWindow = window
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  func openSettings() {
    NSApp.setActivationPolicy(.regular)
    let window = settingsWindow ?? makeSettingsWindow()
    settingsWindow = window
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  private func makeCardManagementWindow() -> NSWindow {
    let window = NSWindow(
      contentRect: NSRect(origin: .zero, size: Self.cardManagementDefaultContentSize),
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered,
      defer: false)
    window.minSize = NSSize(width: 840, height: 560)
    window.isReleasedWhenClosed = false
    window.title = CardManagementStrings.uncategorized
    window.subtitle = String(
      format: CardManagementStrings.cardCountSubtitleFormat,
      0)
    window.collectionBehavior = [.managed]
    window.delegate = self
    let contentViewController = CardManagementSplitViewController(
      memoryCardRepository: memoryCardRepository)
    contentViewController.view.frame = NSRect(
      origin: .zero,
      size: Self.cardManagementDefaultContentSize)
    cardManagementViewController = contentViewController
    cardManagementSplitView = contentViewController.splitView
    window.toolbarStyle = .unified
    window.toolbar = makeCardManagementToolbar()
    window.contentViewController = contentViewController
    window.center()
    return window
  }

  private func makeCardManagementToolbar() -> NSToolbar {
    let toolbar = NSToolbar(identifier: .cardManagement)
    toolbar.delegate = self
    toolbar.displayMode = .iconOnly
    toolbar.allowsUserCustomization = false
    toolbar.autosavesConfiguration = false
    return toolbar
  }

  private func makeSettingsWindow() -> NSWindow {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 560, height: 360),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false)
    window.isReleasedWhenClosed = false
    window.title = SettingsStrings.windowTitle
    window.collectionBehavior = [.auxiliary]
    window.delegate = self
    window.contentViewController = NSHostingController(
      rootView: SettingsView(
        directories: directories,
        launchAtLoginController: launchAtLoginController,
        settingsStore: settingsStore))
    window.center()
    return window
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    if sender === cardManagementWindow {
      cardManagementViewController?.flushPendingEdits()
    }

    sender.orderOut(nil)
    if !hasVisibleManagedWindow(excluding: sender) {
      NSApp.setActivationPolicy(.accessory)
    }
    return false
  }

  private func hasVisibleManagedWindow(excluding excludedWindow: NSWindow) -> Bool {
    [cardManagementWindow, settingsWindow].contains { window in
      guard let window, window !== excludedWindow else {
        return false
      }

      return window.isVisible
    }
  }
}

extension WindowCoordinator: NSToolbarDelegate {
  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    [
      .flexibleSpace,
      .newCategory,
      .toggleSidebar,
      .sidebarTrackingSeparator,
      .flexibleSpace,
      .newCard,
      .space,
      .deleteCard,
    ]
  }

  func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    toolbarDefaultItemIdentifiers(toolbar)
  }

  func toolbar(
    _ toolbar: NSToolbar,
    itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
    willBeInsertedIntoToolbar flag: Bool
  ) -> NSToolbarItem? {
    switch itemIdentifier {
    case .newCategory:
      return toolbarItem(
        identifier: itemIdentifier,
        label: CardManagementStrings.newCategory,
        symbolName: "folder.badge.plus",
        action: #selector(createCategory))
    case .sidebarTrackingSeparator:
      guard let cardManagementSplitView else {
        return nil
      }

      return NSTrackingSeparatorToolbarItem(
        identifier: itemIdentifier,
        splitView: cardManagementSplitView,
        dividerIndex: 0)
    case .newCard:
      return toolbarItem(
        identifier: itemIdentifier,
        label: CardManagementStrings.newCard,
        symbolName: "square.and.pencil",
        action: #selector(createCard))
    case .deleteCard:
      return toolbarItem(
        identifier: itemIdentifier,
        label: CardManagementStrings.deleteCard,
        symbolName: "trash",
        action: #selector(deleteCard))
    default:
      return nil
    }
  }

  private func toolbarItem(
    identifier: NSToolbarItem.Identifier,
    label: String,
    symbolName: String,
    action: Selector
  ) -> NSToolbarItem {
    let item = NSToolbarItem(itemIdentifier: identifier)
    item.label = label
    item.paletteLabel = label
    item.toolTip = label
    item.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: label)
    item.target = self
    item.action = action
    return item
  }

  @objc private func createCategory() {}

  @objc private func createCard() {
    cardManagementViewController?.createCard()
  }

  @objc private func deleteCard() {}
}

extension NSToolbar.Identifier {
  fileprivate static let cardManagement = NSToolbar.Identifier("Gacha.CardManagement")
}

extension NSToolbarItem.Identifier {
  fileprivate static let newCategory = NSToolbarItem.Identifier("Gacha.CardManagement.NewCategory")
  fileprivate static let newCard = NSToolbarItem.Identifier("Gacha.CardManagement.NewCard")
  fileprivate static let deleteCard = NSToolbarItem.Identifier("Gacha.CardManagement.DeleteCard")
}
