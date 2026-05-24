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
  private var cards: [MemoryCard] = []
  private var categories: [CardCategoryItem] = []
  private var selectedDirectory = AppMetadata.defaultCategoryDirectoryName
  private var selectedCardID: String?
  private var draft: Draft?

  init(memoryCardRepository: MemoryCardRepository) {
    self.memoryCardRepository = memoryCardRepository
    super.init(nibName: nil, bundle: nil)

    splitView.isVertical = true
    splitView.dividerStyle = .thin

    addSplitViewItem(Self.categorySplitViewItem(viewController: categoryViewController))
    addSplitViewItem(Self.mainSplitViewItem(viewController: mainViewController))

    categoryViewController.onSelectionChange = { [weak self] directory in
      self?.selectCategory(directory)
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
      clearDraft()
      categoryViewController.setCategories(
        [fallback], selectedDirectory: selectedDirectory)
      mainViewController.setAllCategories([fallback])
      _ = mainViewController.setCards([], selectedCardID: nil)
      updateWindowSummary()
      notifySelectedCardAvailability()
    }
  }

  func createCard() {
    saveDraft()
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
    saveDraft()
    selectedDirectory = directory
    selectedCardID = nil
    reloadData()
  }

  var existingCategoryDirectories: [String] {
    categories.map(\.directory)
  }

  var selectedCard: MemoryCard? {
    guard let selectedCardID else {
      return nil
    }

    return cards.first { $0.id == selectedCardID }
  }

  func flushPendingEdits() {
    saveDraft()
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

  private func selectCategory(_ directory: String) {
    saveDraft()
    selectedDirectory = directory
    selectedCardID = nil
    showSelectedCategory()
  }

  private func selectCard(_ card: MemoryCard?) {
    saveDraft()
    selectedCardID = card?.id
    setDraft(card: card)
    notifySelectedCardAvailability()
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
    setDraft(card: selectedCard)
    updateWindowSummary()
    notifySelectedCardAvailability()
  }

  private func cardBodyDidChange(_ body: String) {
    guard let selectedCardID,
      cards.contains(where: { $0.id == selectedCardID })
    else {
      return
    }

    updateDraftBody(body)
    scheduleSave()
  }

  private func scheduleSave() {
    cancelScheduledSave()
    perform(#selector(saveDraftAfterDelay), with: nil, afterDelay: 0.6)
  }

  @discardableResult
  private func saveDraft() -> Bool {
    cancelScheduledSave()

    guard let draft,
      var card = cards.first(where: { $0.id == draft.id }),
      card.body != draft.body
    else {
      return true
    }

    card.body = draft.body
    card.updatedAt = Date()
    do {
      try memoryCardRepository.write(card)
      try refreshSavedCardList()
      clearDraft()
      return true
    } catch {
      AppLogger.app.error("Failed to save memory card: \(error)")
      return false
    }
  }

  @objc private func saveDraftAfterDelay() {
    saveDraft()
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

  private func setDraft(card: MemoryCard?) {
    guard let card else {
      clearDraft()
      return
    }

    draft = Draft(id: card.id, body: card.body)
  }

  private func updateDraftBody(_ body: String) {
    guard let selectedCardID else {
      clearDraft()
      return
    }

    draft = Draft(id: selectedCardID, body: body)
  }

  private func clearDraft() {
    draft = nil
  }

  private func cancelScheduledSave() {
    NSObject.cancelPreviousPerformRequests(
      withTarget: self,
      selector: #selector(saveDraftAfterDelay),
      object: nil)
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

extension CardManagementSplitViewController {
  func delete(card: MemoryCard) {
    cancelScheduledSave()
    do {
      try memoryCardRepository.delete(id: card.id, directory: card.directory)
      if selectedCardID == card.id {
        selectedCardID = nil
      }
      clearDraft()
      reloadData()
    } catch {
      AppLogger.app.error("Failed to delete memory card: \(error)")
    }
  }

  func moveCard(_ card: MemoryCard, toDirectory directory: String) {
    if !saveDraft() {
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
    cancelScheduledSave()
    do {
      try memoryCardRepository.deleteDirectory(name: directory)
      if selectedDirectory == directory {
        selectedDirectory = AppMetadata.defaultCategoryDirectoryName
      }
      selectedCardID = nil
      clearDraft()
      reloadData()
    } catch {
      AppLogger.app.error("Failed to delete category: \(error)")
    }
  }
}

private struct Draft {
  let id: String
  var body: String
}
