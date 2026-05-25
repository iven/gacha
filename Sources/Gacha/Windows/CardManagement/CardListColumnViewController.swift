import AppKit

final class CardListColumnViewController: NSViewController {
  var onSelectionChange: ((MemoryCard?) -> Void)?
  var onDeleteCard: ((MemoryCard) -> Void)?
  var onMoveCard: ((MemoryCard, String) -> Void)?

  private let tableView = NSTableView()
  private let emptyStateView = CardListEmptyStateView()
  private var cards: [MemoryCard] = []
  private var allCategories: [CardCategoryItem] = []
  private var isUpdatingSelection = false

  override func loadView() {
    let rootView = NSView()
    let scrollView = NSScrollView()

    scrollView.drawsBackground = false
    scrollView.focusRingType = .none
    scrollView.hasVerticalScroller = true
    scrollView.autohidesScrollers = true

    tableView.addTableColumn(NSTableColumn(identifier: .cardTitle))
    tableView.focusRingType = .none
    tableView.headerView = nil
    tableView.intercellSpacing = .zero
    tableView.rowHeight = 56
    tableView.selectionHighlightStyle = .regular
    tableView.allowsEmptySelection = true
    tableView.dataSource = self
    tableView.delegate = self
    tableView.menu = makeContextMenu()

    scrollView.documentView = tableView
    emptyStateView.title = CardManagementStrings.emptyCategory
    emptyStateView.isHidden = !cards.isEmpty

    [scrollView, emptyStateView].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      rootView.addSubview($0)
    }

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: rootView.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),

      emptyStateView.topAnchor.constraint(equalTo: rootView.topAnchor),
      emptyStateView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
      emptyStateView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
      emptyStateView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
    ])

    view = rootView
  }

  func setAllCategories(_ categories: [CardCategoryItem]) {
    allCategories = categories
  }

  func setCards(_ cards: [MemoryCard], selectedCardID: String?) -> MemoryCard? {
    self.cards = cards
    guard isViewLoaded else {
      return selectedCard(in: cards, selectedCardID: selectedCardID)
    }

    emptyStateView.isHidden = !cards.isEmpty

    isUpdatingSelection = true
    defer {
      isUpdatingSelection = false
    }

    tableView.reloadData()
    guard let selectedCard = selectedCard(in: cards, selectedCardID: selectedCardID),
      let selectedRow = cards.firstIndex(where: { $0.id == selectedCard.id })
    else {
      tableView.deselectAll(nil)
      return nil
    }

    tableView.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
    return selectedCard
  }

  private func makeContextMenu() -> NSMenu {
    let menu = NSMenu()
    menu.delegate = self

    let moveItem = NSMenuItem(
      title: CardManagementStrings.moveCardMenuItem,
      action: #selector(moveMenuItemPlaceholder),
      keyEquivalent: "")
    moveItem.target = self
    moveItem.image = NSImage(
      systemSymbolName: "folder",
      accessibilityDescription: CardManagementStrings.moveCardMenuItem)
    moveItem.identifier = .moveCardMenuItem
    moveItem.submenu = NSMenu()
    menu.addItem(moveItem)

    let deleteItem = NSMenuItem(
      title: CardManagementStrings.deleteCardMenuItem,
      action: #selector(deleteClickedCard),
      keyEquivalent: "")
    deleteItem.image = NSImage(
      systemSymbolName: "trash",
      accessibilityDescription: CardManagementStrings.deleteCardMenuItem)
    menu.addItem(deleteItem)

    return menu
  }

  @objc private func moveMenuItemPlaceholder() {}

  @objc private func moveClickedCard(_ sender: NSMenuItem) {
    guard let card = clickedCard(),
      let directory = sender.representedObject as? String
    else {
      return
    }

    onMoveCard?(card, directory)
  }

  private func rebuildMoveSubmenu(card: MemoryCard, into menuItem: NSMenuItem) {
    let submenu = NSMenu()
    let targets = allCategories.filter { $0.directory != card.directory }
    for target in targets {
      let item = NSMenuItem(
        title: target.displayName,
        action: #selector(moveClickedCard(_:)),
        keyEquivalent: "")
      item.target = self
      item.representedObject = target.directory
      submenu.addItem(item)
    }
    menuItem.submenu = submenu
    menuItem.isEnabled = !targets.isEmpty
  }

  @objc private func deleteClickedCard() {
    guard let card = clickedCard() else {
      return
    }

    onDeleteCard?(card)
  }

  private func clickedCard() -> MemoryCard? {
    let row = tableView.clickedRow
    guard cards.indices.contains(row) else {
      return nil
    }

    return cards[row]
  }

  private func selectedCard(in cards: [MemoryCard], selectedCardID: String?) -> MemoryCard? {
    guard let selectedCardID else {
      return cards.first
    }

    return cards.first { $0.id == selectedCardID } ?? cards.first
  }
}

extension CardListColumnViewController: NSMenuItemValidation {
  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    if menuItem.identifier == .moveCardMenuItem {
      return (menuItem.submenu?.items.isEmpty == false)
    }

    return true
  }
}

extension CardListColumnViewController: NSMenuDelegate {
  func menuNeedsUpdate(_ menu: NSMenu) {
    guard let card = clickedCard() else {
      menu.items.forEach { $0.isHidden = true }
      return
    }

    menu.items.forEach { $0.isHidden = false }
    if let moveItem = menu.items.first(where: { $0.identifier == .moveCardMenuItem }) {
      rebuildMoveSubmenu(card: card, into: moveItem)
    }
  }
}

extension CardListColumnViewController: NSTableViewDataSource, NSTableViewDelegate {
  func numberOfRows(in tableView: NSTableView) -> Int {
    cards.count
  }

  func tableView(
    _ tableView: NSTableView,
    viewFor tableColumn: NSTableColumn?,
    row: Int
  ) -> NSView? {
    let item = CardListItem(card: cards[row])
    let cell =
      tableView.makeView(withIdentifier: .cardCell, owner: self) as? CardListCellView
      ?? CardListCellView()
    cell.configure(item)
    return cell
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    guard !isUpdatingSelection else {
      return
    }

    guard tableView.selectedRow >= 0 else {
      onSelectionChange?(nil)
      return
    }

    onSelectionChange?(cards[tableView.selectedRow])
  }
}
