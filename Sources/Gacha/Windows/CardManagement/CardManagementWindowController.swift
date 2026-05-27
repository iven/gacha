import AppKit

@MainActor
final class CardManagementWindowController: NSObject, NSWindowDelegate {
  private static let defaultContentSize = NSSize(width: 960, height: 720)

  var onWindowDidClose: (() -> Void)?
  var onPreviewCardChange: ((MemoryCard?) -> Void)?

  private let memoryCardRepository: MemoryCardRepository
  private(set) weak var splitViewController: CardManagementSplitViewController?
  private weak var splitView: NSSplitView?
  private(set) var window: NSWindow?
  private var isPreviewing = false {
    didSet {
      refreshPreviewToolbarItem()
    }
  }
  private weak var previewToolbarItem: NSToolbarItem?

  init(memoryCardRepository: MemoryCardRepository) {
    self.memoryCardRepository = memoryCardRepository
    super.init()
  }

  func show(editing card: MemoryCard? = nil) {
    let window = self.window ?? makeWindow()
    self.window = window
    if let card {
      splitViewController?.selectCard(id: card.id, in: card.directory)
    }
    window.makeKeyAndOrderFront(nil)
  }

  func validateToolbar() {
    window?.toolbar?.validateVisibleItems()
  }

  private func makeWindow() -> NSWindow {
    let window = NSWindow(
      contentRect: NSRect(origin: .zero, size: Self.defaultContentSize),
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
    contentViewController.onSelectedCardAvailabilityChange = { [weak self] in
      self?.handleSelectedCardChange()
    }
    contentViewController.onRenameCategory = { [weak self] category in
      self?.renameCategory(category)
    }
    contentViewController.onDeleteCategory = { [weak self] category in
      self?.deleteCategory(category)
    }
    contentViewController.onDeleteCard = { [weak self] card in
      self?.requestDelete(card: card)
    }
    contentViewController.onMoveCard = { [weak contentViewController] card, directory in
      contentViewController?.moveCard(card, toDirectory: directory)
    }
    contentViewController.view.frame = NSRect(
      origin: .zero,
      size: Self.defaultContentSize)
    splitViewController = contentViewController
    splitView = contentViewController.splitView
    window.toolbarStyle = .unified
    window.toolbar = makeToolbar()
    window.contentViewController = contentViewController
    window.center()
    return window
  }

  private func makeToolbar() -> NSToolbar {
    let toolbar = NSToolbar(identifier: .cardManagement)
    toolbar.delegate = self
    toolbar.displayMode = .iconOnly
    toolbar.allowsUserCustomization = false
    toolbar.autosavesConfiguration = false
    return toolbar
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    splitViewController?.flushPendingEdits()
    exitPreview()
    sender.orderOut(nil)
    onWindowDidClose?()
    return false
  }

  private func handleSelectedCardChange() {
    validateToolbar()
    if isPreviewing {
      if let card = splitViewController?.selectedCard {
        onPreviewCardChange?(card)
      } else {
        exitPreview()
      }
    }
  }

  private func exitPreview() {
    guard isPreviewing else {
      return
    }
    isPreviewing = false
    onPreviewCardChange?(nil)
    validateToolbar()
  }

  @objc private func togglePreview() {
    if isPreviewing {
      exitPreview()
      return
    }
    guard let card = splitViewController?.selectedCard else {
      return
    }
    isPreviewing = true
    onPreviewCardChange?(card)
    validateToolbar()
  }

  private func refreshPreviewToolbarItem() {
    guard let item = previewToolbarItem else {
      return
    }
    let symbol = isPreviewing ? "eye.fill" : "eye"
    let image = NSImage(
      systemSymbolName: symbol,
      accessibilityDescription: CardManagementStrings.previewCard)
    if isPreviewing {
      item.image = image?.withSymbolConfiguration(
        NSImage.SymbolConfiguration(paletteColors: [.controlAccentColor]))
    } else {
      item.image = image
    }
  }

  fileprivate func renameCategory(_ category: CardCategoryItem) {
    guard let viewController = splitViewController else {
      return
    }

    let oldName = category.directory
    let existing = Set(viewController.existingCategoryDirectories)
      .subtracting([oldName])
    let sheet = CardCategoryNameSheetController.makeRenameCategorySheet(
      currentName: oldName,
      validate: { name in
        validateNewCategoryName(name, existing: existing)
      },
      onRename: { [weak self, weak viewController] newName in
        guard let self, let viewController, newName != oldName else {
          return
        }

        do {
          try memoryCardRepository.renameDirectory(from: oldName, to: newName)
          viewController.selectCategory(named: newName)
        } catch {
          AppLogger.app.error("Failed to rename category: \(error)")
        }
      })
    viewController.presentAsSheet(sheet)
  }

  fileprivate func requestDelete(card: MemoryCard) {
    guard let viewController = splitViewController,
      let window = viewController.view.window
    else {
      return
    }

    confirmCardDeletion(card: card, for: window) { [weak viewController] in
      viewController?.delete(card: card)
    }
  }

  fileprivate func deleteCategory(_ category: CardCategoryItem) {
    guard let viewController = splitViewController,
      let window = viewController.view.window
    else {
      return
    }

    confirmCategoryDeletion(category: category, for: window) { [weak viewController] in
      viewController?.deleteCategory(named: category.directory)
    }
  }

  private func confirmCategoryDeletion(
    category: CardCategoryItem,
    for window: NSWindow,
    confirmed: @escaping () -> Void
  ) {
    DestructiveConfirmationAlert(
      messageText: String.localizedStringWithFormat(
        CardManagementStrings.deleteCategoryConfirmationTitle,
        category.displayName),
      informativeText: String.localizedStringWithFormat(
        CardManagementStrings.deleteCategoryConfirmationMessageFormat,
        category.cardCount),
      confirmTitle: CardManagementStrings.deleteCategoryConfirmationDelete,
      cancelTitle: CardManagementStrings.deleteCategoryConfirmationCancel
    ).present(for: window, confirmed: confirmed)
  }

  private func confirmCardDeletion(
    card: MemoryCard,
    for window: NSWindow,
    confirmed: @escaping () -> Void
  ) {
    DestructiveConfirmationAlert(
      messageText: String.localizedStringWithFormat(
        CardManagementStrings.deleteCardConfirmationTitle,
        CardListItem(card: card).displayTitle),
      informativeText: CardManagementStrings.deleteCardConfirmationMessage,
      confirmTitle: CardManagementStrings.deleteCardConfirmationDelete,
      cancelTitle: CardManagementStrings.deleteCardConfirmationCancel
    ).present(for: window, confirmed: confirmed)
  }
}

extension CardManagementWindowController: NSToolbarDelegate {
  func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
    [
      .flexibleSpace,
      .newCategory,
      .toggleSidebar,
      .sidebarTrackingSeparator,
      .flexibleSpace,
      .newCard,
      .space,
      .previewCard,
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
      guard let splitView else {
        return nil
      }

      return NSTrackingSeparatorToolbarItem(
        identifier: itemIdentifier,
        splitView: splitView,
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
    case .previewCard:
      let item = toolbarItem(
        identifier: itemIdentifier,
        label: CardManagementStrings.previewCard,
        symbolName: "eye",
        action: #selector(togglePreview))
      previewToolbarItem = item
      refreshPreviewToolbarItem()
      return item
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

  @objc private func createCategory() {
    guard let viewController = splitViewController else {
      return
    }

    let existing = Set(viewController.existingCategoryDirectories)
    let sheet = CardCategoryNameSheetController.makeNewCategorySheet(
      validate: { name in
        validateNewCategoryName(name, existing: existing)
      },
      onCreate: { [weak self, weak viewController] name in
        guard let self, let viewController else {
          return
        }

        do {
          try memoryCardRepository.createDirectory(name: name)
          viewController.selectCategory(named: name)
        } catch {
          AppLogger.app.error("Failed to create category: \(error)")
        }
      })
    viewController.presentAsSheet(sheet)
  }

  @objc private func createCard() {
    splitViewController?.createCard()
  }

  @objc private func deleteCard() {
    guard let card = splitViewController?.selectedCard else {
      return
    }

    requestDelete(card: card)
  }
}

extension CardManagementWindowController: NSToolbarItemValidation {
  func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
    switch item.itemIdentifier {
    case .deleteCard:
      return splitViewController?.selectedCard != nil
    case .previewCard:
      return isPreviewing || splitViewController?.selectedCard != nil
    default:
      return true
    }
  }
}

@MainActor
func validateNewCategoryName(
  _ name: String,
  existing: Set<String>
) -> CardCategoryNameSheetController.ValidationResult {
  if name.isEmpty {
    return .invalid(CardManagementStrings.newCategoryErrorEmpty)
  }

  if !MemoryCardFileRepository.isValidCategoryName(name) {
    return .invalid(
      String.localizedStringWithFormat(CardManagementStrings.newCategoryErrorInvalid, name))
  }

  if existing.contains(name) || name == AppMetadata.defaultCategoryDirectoryName {
    return .invalid(
      String.localizedStringWithFormat(CardManagementStrings.newCategoryErrorExists, name))
  }

  return .valid
}
