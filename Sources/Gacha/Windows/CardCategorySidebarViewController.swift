import AppKit

final class CardCategorySidebarViewController: NSViewController {
  var onSelectionChange: ((String) -> Void)?

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

    tableView.addTableColumn(NSTableColumn(identifier: .categoryName))
    tableView.headerView = nil
    tableView.intercellSpacing = NSSize(width: 0, height: 4)
    tableView.rowHeight = 28
    tableView.style = .sourceList
    tableView.allowsEmptySelection = false
    tableView.dataSource = self
    tableView.delegate = self

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

private final class CardCategoryCellView: NSTableCellView {
  private let iconView = NSImageView()
  private let titleField = NSTextField(labelWithString: "")
  private let countField = NSTextField(labelWithString: "")

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    identifier = .categoryCell

    titleField.lineBreakMode = .byTruncatingTail
    countField.textColor = .secondaryLabelColor
    countField.alignment = .right

    [iconView, titleField, countField].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      addSubview($0)
    }

    NSLayoutConstraint.activate([
      iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
      iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
      iconView.widthAnchor.constraint(equalToConstant: 16),
      iconView.heightAnchor.constraint(equalToConstant: 16),

      titleField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 7),
      titleField.centerYAnchor.constraint(equalTo: centerYAnchor),

      countField.leadingAnchor.constraint(
        greaterThanOrEqualTo: titleField.trailingAnchor, constant: 8),
      countField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
      countField.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ category: CardCategoryItem) {
    iconView.image = NSImage(
      systemSymbolName: "folder",
      accessibilityDescription: category.displayName)
    titleField.stringValue = category.displayName
    countField.stringValue = "\(category.cardCount)"
  }
}
