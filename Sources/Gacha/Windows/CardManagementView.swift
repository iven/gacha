import AppKit

final class CardManagementSplitViewController: NSSplitViewController {
  private let memoryCardRepository: MemoryCardRepository
  private let categoryViewController = CardCategorySidebarViewController()
  private let mainViewController = CardMainViewController()
  private var cards: [MemoryCard] = []
  private var categories: [CardCategoryItem] = []
  private var selectedDirectory = AppMetadata.defaultCategoryDirectoryName
  private var selectedCardID: String?
  private var selectedCategory: CardCategoryItem?

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
    mainViewController.onCardSelectionChange = { [weak self] card in
      self?.selectedCardID = card?.id
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
      showSelectedCategory()
    } catch {
      AppLogger.app.error("Failed to load card management data: \(error.localizedDescription)")
      let fallback = CardCategoryItem(
        directory: AppMetadata.defaultCategoryDirectoryName,
        displayName: CardManagementStrings.uncategorized,
        cardCount: 0)
      selectedCategory = fallback
      selectedCardID = nil
      categoryViewController.setCategories(
        [fallback], selectedDirectory: selectedDirectory)
      _ = mainViewController.setCards([], selectedCardID: nil)
      updateWindowSummary()
    }
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
    selectedDirectory = directory
    selectedCardID = nil
    showSelectedCategory()
  }

  private func makeCategoryItems(cards: [MemoryCard]) throws -> [CardCategoryItem] {
    CardCategoryList.items(
      directories: try memoryCardRepository.listDirectories(),
      cards: cards)
  }

  private func showSelectedCategory() {
    selectedCategory = categories.first { $0.directory == selectedDirectory }
    let categoryCards = cards.filter { $0.directory == selectedDirectory }
    let selectedCard = mainViewController.setCards(
      categoryCards,
      selectedCardID: selectedCardID)
    selectedCardID = selectedCard?.id
    updateWindowSummary()
  }

  private func updateWindowSummary() {
    guard let selectedCategory else {
      return
    }

    view.window?.title = selectedCategory.displayName
    view.window?.subtitle = String(
      format: CardManagementStrings.cardCountSubtitleFormat,
      selectedCategory.cardCount)
  }
}
