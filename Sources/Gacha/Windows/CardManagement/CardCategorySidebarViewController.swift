import AppKit

final class CardCategorySidebarViewController: NSViewController {
  var onSelectionChange: ((String) -> Void)?
  var onRenameCategory: ((CardCategoryItem) -> Void)?
  var onDeleteCategory: ((CardCategoryItem) -> Void)?

  private let tableView = NSTableView()
  private var categories: [CardCategoryItem] = []
  private var isUpdatingSelection = false

  override func loadView() {
    let rootView = NSView()
    let scrollView = NSScrollView()
    let title = NSTextField(labelWithString: CardManagementStrings.sidebarTitle)

    title.font = .systemFont(ofSize: 11, weight: .semibold)
    title.textColor = .tertiaryLabelColor
    scrollView.drawsBackground = false
    scrollView.hasVerticalScroller = true
    scrollView.autohidesScrollers = true

    tableView.addTableColumn(NSTableColumn(identifier: .categoryName))
    tableView.headerView = nil
    tableView.intercellSpacing = NSSize(width: 0, height: 4)
    tableView.rowHeight = 28
    tableView.style = .sourceList
    tableView.allowsEmptySelection = false
    tableView.dataSource = self
    tableView.delegate = self
    tableView.menu = makeContextMenu()

    scrollView.documentView = tableView

    [title, scrollView].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      rootView.addSubview($0)
    }

    NSLayoutConstraint.activate([
      title.topAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.topAnchor, constant: 12),
      title.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 18),
      title.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -18),

      scrollView.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 12),
      scrollView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
    ])

    view = rootView
  }

  private func makeContextMenu() -> NSMenu {
    let menu = NSMenu()
    menu.delegate = self
    let renameItem = NSMenuItem(
      title: CardManagementStrings.renameCategoryMenuItem,
      action: #selector(renameClickedCategory),
      keyEquivalent: "")
    renameItem.image = NSImage(
      systemSymbolName: "pencil",
      accessibilityDescription: CardManagementStrings.renameCategoryMenuItem)
    menu.addItem(renameItem)
    let deleteItem = NSMenuItem(
      title: CardManagementStrings.deleteCategoryMenuItem,
      action: #selector(deleteClickedCategory),
      keyEquivalent: "")
    deleteItem.image = NSImage(
      systemSymbolName: "trash",
      accessibilityDescription: CardManagementStrings.deleteCategoryMenuItem)
    menu.addItem(deleteItem)
    return menu
  }

  @objc private func renameClickedCategory() {
    guard let category = clickedUserCategory() else {
      return
    }

    onRenameCategory?(category)
  }

  @objc private func deleteClickedCategory() {
    guard let category = clickedUserCategory() else {
      return
    }

    onDeleteCategory?(category)
  }

  private func clickedUserCategory() -> CardCategoryItem? {
    let row = tableView.clickedRow
    guard categories.indices.contains(row) else {
      return nil
    }

    let category = categories[row]
    guard category.directory != AppMetadata.defaultCategoryDirectoryName else {
      return nil
    }

    return category
  }

  func setCategories(_ categories: [CardCategoryItem], selectedDirectory: String) {
    self.categories = categories
    guard isViewLoaded else {
      return
    }

    isUpdatingSelection = true
    defer {
      isUpdatingSelection = false
    }

    tableView.reloadData()
    let selectedRow = categories.firstIndex { $0.directory == selectedDirectory } ?? 0
    tableView.selectRowIndexes(IndexSet(integer: selectedRow), byExtendingSelection: false)
  }
}

extension CardCategorySidebarViewController: NSMenuDelegate {
  func menuNeedsUpdate(_ menu: NSMenu) {
    let isUserCategory = clickedUserCategory() != nil
    menu.items.forEach { $0.isHidden = !isUserCategory }
  }
}

extension CardCategorySidebarViewController: NSTableViewDataSource, NSTableViewDelegate {
  func numberOfRows(in tableView: NSTableView) -> Int {
    categories.count
  }

  func tableView(
    _ tableView: NSTableView,
    viewFor tableColumn: NSTableColumn?,
    row: Int
  ) -> NSView? {
    let category = categories[row]
    let cell =
      tableView.makeView(withIdentifier: .categoryCell, owner: self) as? CardCategoryCellView
      ?? CardCategoryCellView()
    cell.configure(category)
    return cell
  }

  func tableViewSelectionDidChange(_ notification: Notification) {
    guard !isUpdatingSelection, tableView.selectedRow >= 0 else {
      return
    }

    onSelectionChange?(categories[tableView.selectedRow].directory)
  }
}
