import AppKit

final class CardManagementSplitViewController: NSSplitViewController {
  init() {
    super.init(nibName: nil, bundle: nil)

    splitView.isVertical = true
    splitView.dividerStyle = .thin

    addSplitViewItem(Self.categorySplitViewItem())
    addSplitViewItem(Self.mainSplitViewItem())
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private static func categorySplitViewItem() -> NSSplitViewItem {
    let item = NSSplitViewItem(sidebarWithViewController: CardCategorySidebarViewController())
    item.minimumThickness = 210
    item.maximumThickness = 280
    item.preferredThicknessFraction = 0.22
    item.canCollapse = true
    return item
  }

  private static func mainSplitViewItem() -> NSSplitViewItem {
    let item = NSSplitViewItem(viewController: CardMainViewController())
    item.minimumThickness = 660
    item.canCollapse = false
    return item
  }
}

private final class CardCategorySidebarViewController: NSViewController {
  private let tableView = NSTableView()
  private let categories = [CardManagementStrings.uncategorized]

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

    tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
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
    let cell = NSTableCellView()
    let icon = NSImageView(
      image: NSImage(
        systemSymbolName: "folder",
        accessibilityDescription: categories[row]) ?? NSImage())
    let title = NSTextField(labelWithString: categories[row])
    let count = NSTextField(labelWithString: "0")

    title.lineBreakMode = .byTruncatingTail
    count.textColor = .secondaryLabelColor
    count.alignment = .right

    [icon, title, count].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      cell.addSubview($0)
    }

    NSLayoutConstraint.activate([
      icon.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
      icon.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
      icon.widthAnchor.constraint(equalToConstant: 16),
      icon.heightAnchor.constraint(equalToConstant: 16),

      title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 7),
      title.centerYAnchor.constraint(equalTo: cell.centerYAnchor),

      count.leadingAnchor.constraint(greaterThanOrEqualTo: title.trailingAnchor, constant: 8),
      count.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
      count.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
    ])

    return cell
  }
}

private final class CardMainViewController: NSViewController {
  private let splitViewController = NSSplitViewController()
  private var contentTopConstraint: NSLayoutConstraint?

  override func loadView() {
    let rootView = NSView()

    splitViewController.splitView.isVertical = true
    splitViewController.splitView.dividerStyle = .thin
    splitViewController.addSplitViewItem(Self.cardListSplitViewItem())
    splitViewController.addSplitViewItem(Self.editorPreviewSplitViewItem())

    addChild(splitViewController)

    let separator = NSBox()
    separator.boxType = .separator

    splitViewController.view.translatesAutoresizingMaskIntoConstraints = false
    separator.translatesAutoresizingMaskIntoConstraints = false
    rootView.addSubview(splitViewController.view)
    rootView.addSubview(separator)

    let topConstraint = splitViewController.view.topAnchor.constraint(
      equalTo: rootView.safeAreaLayoutGuide.topAnchor)
    contentTopConstraint = topConstraint
    NSLayoutConstraint.activate([
      topConstraint,
      splitViewController.view.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
      splitViewController.view.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
      splitViewController.view.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),

      separator.topAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.topAnchor),
      separator.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
      separator.heightAnchor.constraint(equalToConstant: 1),
    ])

    view = rootView
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    guard let contentLayoutGuide = view.window?.contentLayoutGuide as? NSLayoutGuide else {
      return
    }

    contentTopConstraint?.isActive = false
    contentTopConstraint = splitViewController.view.topAnchor.constraint(
      equalTo: contentLayoutGuide.topAnchor)
    contentTopConstraint?.isActive = true
  }

  private static func cardListSplitViewItem() -> NSSplitViewItem {
    let item = NSSplitViewItem(viewController: CardListColumnViewController())
    item.minimumThickness = 210
    item.maximumThickness = 280
    item.preferredThicknessFraction = 0.19
    item.holdingPriority = .defaultHigh
    item.canCollapse = false
    return item
  }

  private static func editorPreviewSplitViewItem() -> NSSplitViewItem {
    let item = NSSplitViewItem(viewController: CardEditorPreviewSplitViewController())
    item.minimumThickness = 640
    item.holdingPriority = .defaultLow
    item.canCollapse = false
    return item
  }
}

private final class CardListColumnViewController: NSViewController {
  private let tableView = NSTableView()

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
    tableView.dataSource = self
    tableView.delegate = self

    scrollView.documentView = tableView

    scrollView.translatesAutoresizingMaskIntoConstraints = false
    rootView.addSubview(scrollView)

    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: rootView.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
    ])

    view = rootView
  }
}

extension CardListColumnViewController: NSTableViewDataSource, NSTableViewDelegate {
  func numberOfRows(in tableView: NSTableView) -> Int {
    0
  }
}

private final class CardEditorPreviewSplitViewController: NSSplitViewController {
  init() {
    super.init(nibName: nil, bundle: nil)

    splitView.isVertical = false
    splitView.dividerStyle = .thin

    addSplitViewItem(Self.editorPaneSplitViewItem())
    addSplitViewItem(Self.previewPaneSplitViewItem())
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private static func editorPaneSplitViewItem() -> NSSplitViewItem {
    let item = NSSplitViewItem(
      viewController: CardTextPaneViewController(title: CardManagementStrings.editorPane))
    item.minimumThickness = 250
    item.canCollapse = false
    return item
  }

  private static func previewPaneSplitViewItem() -> NSSplitViewItem {
    let item = NSSplitViewItem(
      viewController: CardTextPaneViewController(title: CardManagementStrings.previewPane))
    item.minimumThickness = 250
    item.canCollapse = false
    return item
  }
}

private final class CardTextPaneViewController: NSViewController {
  private let paneTitle: String

  init(title: String) {
    paneTitle = title
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let scrollView = NSTextView.scrollableTextView()
    guard let textView = scrollView.documentView as? NSTextView else {
      view = scrollView
      return
    }

    scrollView.drawsBackground = true
    scrollView.backgroundColor = .textBackgroundColor

    textView.string = paneTitle
    textView.font = .preferredFont(forTextStyle: .headline)
    textView.textColor = .secondaryLabelColor
    textView.backgroundColor = .textBackgroundColor
    textView.isEditable = false
    textView.isSelectable = false
    textView.textContainerInset = NSSize(width: 20, height: 20)

    view = scrollView
  }
}

extension NSUserInterfaceItemIdentifier {
  fileprivate static let categoryName = NSUserInterfaceItemIdentifier(
    "Gacha.CardManagement.CategoryName")
  fileprivate static let cardTitle = NSUserInterfaceItemIdentifier("Gacha.CardManagement.CardTitle")
}
