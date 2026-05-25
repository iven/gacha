import AppKit

final class CardManagementSplitViewController: NSSplitViewController {
  var onSelectedCardAvailabilityChange: (() -> Void)?
  var onRenameCategory: ((CardCategoryItem) -> Void)?
  var onDeleteCategory: ((CardCategoryItem) -> Void)?
  var onDeleteCard: ((MemoryCard) -> Void)?
  var onMoveCard: ((MemoryCard, String) -> Void)?

  private let memoryCardRepository: MemoryCardRepository
  private let categoryViewController = CardCategorySidebarViewController()
  private let mainViewController = CardMainViewController()
  private let draftSession: CardDraftSession
  private var cards: [MemoryCard] = []
  private var categories: [CardCategoryItem] = []
  private var selectedDirectory = AppMetadata.defaultCategoryDirectoryName
  private var selectedCardID: String?

  init(memoryCardRepository: MemoryCardRepository) {
    self.memoryCardRepository = memoryCardRepository
    draftSession = CardDraftSession(memoryCardRepository: memoryCardRepository)
    super.init(nibName: nil, bundle: nil)

    splitView.isVertical = true
    splitView.dividerStyle = .thin

    addSplitViewItem(Self.categorySplitViewItem(viewController: categoryViewController))
    addSplitViewItem(Self.mainSplitViewItem(viewController: mainViewController))

    bindChildCallbacks()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    reloadData()
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    updateWindowSummary()
  }

  var selectedCard: MemoryCard? {
    guard let selectedCardID else {
      return nil
    }

    return cards.first { $0.id == selectedCardID }
  }

  var existingCategoryDirectories: [String] {
    categories.map(\.directory)
  }

  func reloadData() {
    do {
      cards = try memoryCardRepository.list()
      categories = try makeCategoryItems(cards: cards)
      if !categories.contains(where: { $0.directory == selectedDirectory }) {
        selectedDirectory = AppMetadata.defaultCategoryDirectoryName
        selectedCardID = nil
      }

      categoryViewController.setCategories(categories, selectedDirectory: selectedDirectory)
      mainViewController.setAllCategories(categories)
      showSelectedCategory()
    } catch {
      AppLogger.app.error("Failed to load card management data: \(error)")
      let fallback = CardCategoryItem(
        directory: AppMetadata.defaultCategoryDirectoryName,
        displayName: CardManagementStrings.uncategorized,
        cardCount: 0)
      selectedCardID = nil
      draftSession.discard()
      categoryViewController.setCategories(
        [fallback], selectedDirectory: selectedDirectory)
      mainViewController.setAllCategories([fallback])
      _ = mainViewController.setCards([], selectedCardID: nil)
      updateWindowSummary()
      notifySelectedCardAvailability()
    }
  }

  func createCard() {
    flushDraft()
    do {
      let directory = selectedDirectory
      let card = try memoryCardRepository.create(body: "", directory: directory)
      selectedDirectory = card.directory
      selectedCardID = card.id
      reloadData()
      mainViewController.focusEditor()
    } catch {
      AppLogger.app.error("Failed to create memory card: \(error)")
    }
  }

  func selectCategory(named directory: String) {
    flushDraft()
    selectedDirectory = directory
    selectedCardID = nil
    reloadData()
  }

  func delete(card: MemoryCard) {
    draftSession.cancelScheduledFlush()
    do {
      try memoryCardRepository.delete(id: card.id, directory: card.directory)
      if selectedCardID == card.id {
        selectedCardID = nil
      }
      draftSession.discard()
      reloadData()
    } catch {
      AppLogger.app.error("Failed to delete memory card: \(error)")
    }
  }

  func moveCard(_ card: MemoryCard, toDirectory directory: String) {
    if !flushDraft() {
      return
    }

    guard var fresh = cards.first(where: { $0.id == card.id }) else {
      return
    }

    fresh.directory = directory
    fresh.updatedAt = Date()
    do {
      try memoryCardRepository.write(fresh)
      selectedDirectory = directory
      selectedCardID = fresh.id
      reloadData()
    } catch {
      AppLogger.app.error("Failed to move memory card: \(error)")
    }
  }

  func deleteCategory(named directory: String) {
    draftSession.cancelScheduledFlush()
    do {
      try memoryCardRepository.deleteDirectory(name: directory)
      if selectedDirectory == directory {
        selectedDirectory = AppMetadata.defaultCategoryDirectoryName
      }
      selectedCardID = nil
      draftSession.discard()
      reloadData()
    } catch {
      AppLogger.app.error("Failed to delete category: \(error)")
    }
  }

  func flushPendingEdits() {
    flushDraft()
  }

  private static func categorySplitViewItem(
    viewController: CardCategorySidebarViewController
  ) -> NSSplitViewItem {
    let item = NSSplitViewItem(sidebarWithViewController: viewController)
    item.minimumThickness = 210
    item.maximumThickness = 280
    item.preferredThicknessFraction = 0.22
    item.canCollapse = true
    return item
  }

  private static func mainSplitViewItem(
    viewController: CardMainViewController
  ) -> NSSplitViewItem {
    let item = NSSplitViewItem(viewController: viewController)
    item.minimumThickness = 660
    item.canCollapse = false
    return item
  }
}

extension CardManagementSplitViewController {
  private func bindChildCallbacks() {
    categoryViewController.onSelectionChange = { [weak self] directory in
      self?.selectInternalCategory(directory)
    }
    categoryViewController.onRenameCategory = { [weak self] category in
      self?.onRenameCategory?(category)
    }
    categoryViewController.onDeleteCategory = { [weak self] category in
      self?.onDeleteCategory?(category)
    }
    mainViewController.onCardSelectionChange = { [weak self] card in
      self?.selectCard(card)
    }
    mainViewController.onCardBodyChange = { [weak self] body in
      self?.cardBodyDidChange(body)
    }
    mainViewController.onEmptyStateClick = { [weak self] in
      self?.createCard()
    }
    mainViewController.onDeleteCard = { [weak self] card in
      self?.onDeleteCard?(card)
    }
    mainViewController.onMoveCard = { [weak self] card, directory in
      self?.onMoveCard?(card, directory)
    }
    draftSession.onDebouncedFlushNeeded = { [weak self] in
      self?.flushDraft()
    }
  }

  private func selectInternalCategory(_ directory: String) {
    flushDraft()
    selectedDirectory = directory
    selectedCardID = nil
    showSelectedCategory()
  }

  private func selectCard(_ card: MemoryCard?) {
    flushDraft()
    selectedCardID = card?.id
    draftSession.begin(card: card)
    notifySelectedCardAvailability()
  }

  private func cardBodyDidChange(_ body: String) {
    guard let selectedCardID,
      cards.contains(where: { $0.id == selectedCardID })
    else {
      return
    }

    draftSession.update(body: body, for: selectedCardID)
    draftSession.scheduleFlush()
  }

  @discardableResult
  private func flushDraft() -> Bool {
    switch draftSession.flush(against: cards) {
    case .noChange:
      return true
    case .saved:
      do {
        try refreshSavedCardList()
      } catch {
        AppLogger.app.error("Failed to refresh after save: \(error)")
      }
      return true
    case .failure:
      return false
    }
  }

  private func makeCategoryItems(cards: [MemoryCard]) throws -> [CardCategoryItem] {
    CardCategoryList.items(
      directories: try memoryCardRepository.listDirectories(),
      cards: cards)
  }

  private func showSelectedCategory() {
    let categoryCards = cards.filter { $0.directory == selectedDirectory }
    let selectedCard = mainViewController.setCards(
      categoryCards,
      selectedCardID: selectedCardID)
    selectedCardID = selectedCard?.id
    draftSession.begin(card: selectedCard)
    updateWindowSummary()
    notifySelectedCardAvailability()
  }

  private func refreshSavedCardList() throws {
    cards = try memoryCardRepository.list()
    categories = try makeCategoryItems(cards: cards)
    categoryViewController.setCategories(categories, selectedDirectory: selectedDirectory)
    mainViewController.setAllCategories(categories)
    let categoryCards = cards.filter { $0.directory == selectedDirectory }
    _ = mainViewController.setCardList(categoryCards, selectedCardID: selectedCardID)
    updateWindowSummary()
  }

  private func notifySelectedCardAvailability() {
    onSelectedCardAvailabilityChange?()
  }

  private func updateWindowSummary() {
    guard let selectedCategory = categories.first(where: { $0.directory == selectedDirectory })
    else {
      return
    }

    view.window?.title = selectedCategory.displayName
    view.window?.subtitle = String(
      format: CardManagementStrings.cardCountSubtitleFormat,
      selectedCategory.cardCount)
  }
}
