import AppKit

final class CardListColumnViewController: NSViewController {
  var onSelectionChange: ((MemoryCard?) -> Void)?

  private let tableView = NSTableView()
  private let emptyStateView = CardListEmptyStateView()
  private var cards: [MemoryCard] = []
  private var isUpdatingSelection = false

  override func loadView() {
    let rootView = NSView()
    let scrollView = NSScrollView()

    scrollView.drawsBackground = false
    scrollView.focusRingType = .none
    scrollView.hasVerticalScroller = true

    tableView.addTableColumn(NSTableColumn(identifier: .cardTitle))
    tableView.focusRingType = .none
    tableView.headerView = nil
    tableView.intercellSpacing = .zero
    tableView.rowHeight = 56
    tableView.selectionHighlightStyle = .regular
    tableView.allowsEmptySelection = true
    tableView.dataSource = self
    tableView.delegate = self

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

  private func selectedCard(in cards: [MemoryCard], selectedCardID: String?) -> MemoryCard? {
    guard let selectedCardID else {
      return cards.first
    }

    return cards.first { $0.id == selectedCardID } ?? cards.first
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

private final class CardListEmptyStateView: NSView {
  var title: String {
    get { titleField.stringValue }
    set { titleField.stringValue = newValue }
  }

  private let titleField = NSTextField(labelWithString: "")

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    titleField.font = .systemFont(ofSize: 30, weight: .semibold)
    titleField.textColor = .tertiaryLabelColor

    titleField.translatesAutoresizingMaskIntoConstraints = false
    addSubview(titleField)

    NSLayoutConstraint.activate([
      titleField.centerXAnchor.constraint(equalTo: centerXAnchor),
      titleField.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -24),
      titleField.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
      titleField.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

private final class CardListCellView: NSTableCellView {
  private let titleField = NSTextField(labelWithString: "")
  private let subtitleField = NSTextField(labelWithString: "")

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    identifier = .cardCell

    titleField.font = .preferredFont(forTextStyle: .body)
    titleField.lineBreakMode = .byTruncatingTail
    subtitleField.font = .preferredFont(forTextStyle: .caption1)
    subtitleField.textColor = .secondaryLabelColor
    subtitleField.lineBreakMode = .byTruncatingTail

    [titleField, subtitleField].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      addSubview($0)
    }

    NSLayoutConstraint.activate([
      titleField.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      titleField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      titleField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

      subtitleField.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 3),
      subtitleField.leadingAnchor.constraint(equalTo: titleField.leadingAnchor),
      subtitleField.trailingAnchor.constraint(equalTo: titleField.trailingAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ item: CardListItem) {
    titleField.stringValue = item.displayTitle
    subtitleField.stringValue = item.subtitle
  }
}
