import AppKit

final class CardMainViewController: NSViewController {
  var onCardSelectionChange: ((MemoryCard?) -> Void)?
  var onCardBodyChange: ((String) -> Void)?
  var onEmptyStateClick: (() -> Void)?
  var onDeleteCard: ((MemoryCard) -> Void)?
  var onMoveCard: ((MemoryCard, String) -> Void)?

  private let splitViewController = NSSplitViewController()
  private let cardListViewController = CardListColumnViewController()
  private let editorViewController = CardEditorViewController(
    syntaxHighlighter: MarkdownSyntaxHighlighter())
  private var contentTopConstraint: NSLayoutConstraint?

  override func loadView() {
    let rootView = NSView()

    cardListViewController.onSelectionChange = { [weak self] card in
      self?.show(card: card)
      self?.onCardSelectionChange?(card)
    }
    cardListViewController.onDeleteCard = { [weak self] card in
      self?.onDeleteCard?(card)
    }
    cardListViewController.onMoveCard = { [weak self] card, directory in
      self?.onMoveCard?(card, directory)
    }
    editorViewController.onTextChange = { [weak self] body in
      self?.onCardBodyChange?(body)
    }
    editorViewController.onClick = { [weak self] in
      self?.onEmptyStateClick?()
    }

    splitViewController.splitView.isVertical = true
    splitViewController.splitView.dividerStyle = .thin
    splitViewController.addSplitViewItem(
      Self.cardListSplitViewItem(viewController: cardListViewController))
    splitViewController.addSplitViewItem(
      Self.editorSplitViewItem(viewController: editorViewController))

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

  func setCards(_ cards: [MemoryCard], selectedCardID: String?) -> MemoryCard? {
    let selectedCard = cardListViewController.setCards(cards, selectedCardID: selectedCardID)
    show(card: selectedCard)
    return selectedCard
  }

  func setCardList(_ cards: [MemoryCard], selectedCardID: String?) -> MemoryCard? {
    cardListViewController.setCards(cards, selectedCardID: selectedCardID)
  }

  func setAllCategories(_ categories: [CardCategoryItem]) {
    cardListViewController.setAllCategories(categories)
  }

  func focusEditor() {
    editorViewController.focusTextView()
  }

  private func show(card: MemoryCard?) {
    let isEmptyState = card == nil
    editorViewController.setText(card?.body ?? "")
    editorViewController.setEditable(card != nil)
    editorViewController.setClickHandlingEnabled(isEmptyState)
  }

  private static func cardListSplitViewItem(
    viewController: CardListColumnViewController
  ) -> NSSplitViewItem {
    let item = NSSplitViewItem(viewController: viewController)
    item.minimumThickness = 210
    item.maximumThickness = 280
    item.preferredThicknessFraction = 0.19
    item.holdingPriority = .defaultHigh
    item.canCollapse = false
    return item
  }

  private static func editorSplitViewItem(
    viewController: CardEditorViewController
  ) -> NSSplitViewItem {
    let item = NSSplitViewItem(viewController: viewController)
    item.minimumThickness = 640
    item.holdingPriority = .defaultLow
    item.canCollapse = false
    return item
  }
}
