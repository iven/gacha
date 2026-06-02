import Combine
import Foundation

@MainActor
final class CardManagementModel: ObservableObject {
  @Published private(set) var cards: [MemoryCard] = []
  @Published private(set) var categories: [CardCategoryItem] = []
  @Published var selectedCategoryName = AppMetadata.defaultCategoryDirectoryName
  @Published var selectedCardID: String?
  @Published private(set) var editorText = ""
  @Published var activeSheet: ActiveSheet?
  @Published var pendingDeletion: PendingDeletion?
  @Published private(set) var isPreviewing = false
  @Published private(set) var editorFocusRevision: Int = 0

  private let memoryCardRepository: MemoryCardRepository
  private let cardWindowBridge: CardWindowBridge
  private let draftSession: CardDraftSession
  private var repositoryEventObservation: AnyCancellable?
  private var togglePreviewObservation: AnyCancellable?

  init(memoryCardRepository: MemoryCardRepository, cardWindowBridge: CardWindowBridge) {
    self.memoryCardRepository = memoryCardRepository
    self.cardWindowBridge = cardWindowBridge
    draftSession = CardDraftSession(memoryCardRepository: memoryCardRepository)
    draftSession.onDebouncedFlushNeeded = { [weak self] in
      self?.flushDraft()
    }
    reloadData()
    repositoryEventObservation =
      memoryCardRepository.events
      .receive(on: DispatchQueue.main)
      .sink { [weak self] event in
        self?.handleRepositoryEvent(event)
      }
    // Bridge is the single source of truth for preview state. Keeping this
    // mirror in the model means the toolbar toggle stays in sync no matter
    // who clears the preview (this window, the notch eye.fill button, Esc, or
    // the global toggle shortcut).
    cardWindowBridge.$previewCard
      .map { $0 != nil }
      .removeDuplicates()
      .assign(to: &$isPreviewing)
    togglePreviewObservation =
      cardWindowBridge.togglePreviewRequest
      .sink { [weak self] in self?.togglePreview() }
  }
}

// MARK: - Selection

extension CardManagementModel {
  func selectCategory(_ name: String) {
    guard name != selectedCategoryName else {
      return
    }

    flushDraft()
    selectedCategoryName = name
    selectedCardID = nil
    showSelectedCategory()
  }

  func selectCard(id: String?) {
    guard id != selectedCardID else {
      return
    }

    flushDraft()
    selectedCardID = id
    applySelectedCardText()
    draftSession.begin(card: selectedCard)
    refreshPreview()
  }

  /// Switches to a card in a specific category and reloads. Internal helper for
  /// `selectCard(byID:)`.
  fileprivate func selectCard(id: String, inCategory categoryName: String) {
    flushDraft()
    selectedCategoryName = categoryName
    selectedCardID = id
    reloadData()
  }

  /// Selects a card by id alone, resolving its category from the loaded cards.
  /// External entry for the notch ✏️ edit flow, which only carries a card id.
  func selectCard(byID id: String) {
    guard let card = cards.first(where: { $0.id == id }) else {
      return
    }

    selectCard(id: card.id, inCategory: card.directory)
  }
}

// MARK: - Editing

extension CardManagementModel {
  func updateBody(_ body: String) {
    guard let selectedCardID,
      cards.contains(where: { $0.id == selectedCardID })
    else {
      return
    }

    editorText = body
    draftSession.update(body: body, for: selectedCardID)
    draftSession.scheduleFlush()
  }

  func flushPendingEdits() {
    flushDraft()
  }
}

// MARK: - Card lifecycle

extension CardManagementModel {
  func createCard() {
    flushDraft()
    do {
      _ = try memoryCardRepository.create(
        body: "",
        directory: selectedCategoryName,
        focusEditor: true)
    } catch {
      AppLogger.app.error("Failed to create memory card: \(error)")
    }
  }

  func delete(card: MemoryCard) {
    draftSession.cancelScheduledFlush()
    do {
      try memoryCardRepository.delete(id: card.id, directory: card.directory)
    } catch {
      AppLogger.app.error("Failed to delete memory card: \(error)")
    }
  }

  func moveCard(_ card: MemoryCard, toCategory categoryName: String) {
    if !flushDraft() {
      return
    }

    guard var fresh = cards.first(where: { $0.id == card.id }) else {
      return
    }

    fresh.directory = categoryName
    fresh.updatedAt = Date()
    do {
      try memoryCardRepository.write(fresh)
      selectedCategoryName = categoryName
      selectedCardID = fresh.id
    } catch {
      AppLogger.app.error("Failed to move memory card: \(error)")
    }
  }
}

// MARK: - Category lifecycle

extension CardManagementModel {
  func createCategory(name: String) {
    do {
      try memoryCardRepository.createDirectory(name: name)
      selectCategoryAndReload(named: name)
    } catch {
      AppLogger.app.error("Failed to create category: \(error)")
    }
  }

  func renameCategory(_ category: CardCategoryItem, to newName: String) {
    let oldName = category.name
    guard newName != oldName else {
      return
    }

    do {
      try memoryCardRepository.renameDirectory(from: oldName, to: newName)
      selectCategoryAndReload(named: newName)
    } catch {
      AppLogger.app.error("Failed to rename category: \(error)")
    }
  }

  func deleteCategory(_ category: CardCategoryItem) {
    draftSession.cancelScheduledFlush()
    do {
      try memoryCardRepository.deleteDirectory(name: category.name)
    } catch {
      AppLogger.app.error("Failed to delete category: \(error)")
    }
  }

  /// Returns a localized error message when the name is invalid, or `nil` when
  /// it is acceptable.
  func validateCategoryName(_ name: String, excluding excluded: String? = nil) -> String? {
    var existing = Set(existingCategoryNames)
    if let excluded {
      existing.remove(excluded)
    }

    if name.isEmpty {
      return CardManagementStrings.newCategoryErrorEmpty
    }

    if !MemoryCardFileRepository.isValidCategoryName(name) {
      return String.localizedStringWithFormat(
        CardManagementStrings.newCategoryErrorInvalid, name)
    }

    if existing.contains(name) || name == AppMetadata.defaultCategoryDirectoryName {
      return String.localizedStringWithFormat(
        CardManagementStrings.newCategoryErrorExists, name)
    }

    return nil
  }
}

// MARK: - Preview

extension CardManagementModel {
  func togglePreview() {
    if isPreviewing {
      cardWindowBridge.previewCard = nil
    } else if let card = selectedCard {
      cardWindowBridge.previewCard = card
    }
  }

  func exitPreview() {
    cardWindowBridge.previewCard = nil
  }

  // Keeps the notch preview in sync when the selected card changes; drops out
  // of preview when no card remains selected.
  fileprivate func refreshPreview() {
    guard isPreviewing else {
      return
    }
    cardWindowBridge.previewCard = selectedCard
  }
}

// MARK: - Data loading

extension CardManagementModel {
  fileprivate func selectCategoryAndReload(named name: String) {
    flushDraft()
    selectedCategoryName = name
    selectedCardID = nil
    reloadData()
  }

  fileprivate func reloadData() {
    do {
      cards = try memoryCardRepository.list()
      categories = try makeCategoryItems(cards: cards)
      if !categories.contains(where: { $0.name == selectedCategoryName }) {
        selectedCategoryName = AppMetadata.defaultCategoryDirectoryName
        selectedCardID = nil
      }
      showSelectedCategory()
    } catch {
      AppLogger.app.error("Failed to load card management data: \(error)")
      categories = [
        CardCategoryItem(
          name: AppMetadata.defaultCategoryDirectoryName,
          displayName: CardManagementStrings.uncategorized,
          cardCount: 0)
      ]
      cards = []
      selectedCardID = nil
      draftSession.discard()
      applySelectedCardText()
      refreshPreview()
    }
  }

  fileprivate func handleRepositoryEvent(_ event: MemoryCardRepositoryEvent) {
    let shouldFocusNewCard: Bool
    switch event {
    case .didCreate(let card, focusEditor: true):
      selectedCategoryName = card.directory
      selectedCardID = card.id
      shouldFocusNewCard = true
    case .didDelete(let id, _) where selectedCardID == id:
      selectedCardID = nil
      draftSession.discard()
      shouldFocusNewCard = false
    case .didDeleteDirectory(let name) where selectedCategoryName == name:
      selectedCategoryName = AppMetadata.defaultCategoryDirectoryName
      selectedCardID = nil
      draftSession.discard()
      shouldFocusNewCard = false
    default:
      shouldFocusNewCard = false
    }

    do {
      cards = try memoryCardRepository.list()
      categories = try makeCategoryItems(cards: cards)
    } catch {
      AppLogger.app.error("Failed to refresh card management after repository event: \(error)")
      return
    }

    if !categories.contains(where: { $0.name == selectedCategoryName }) {
      selectedCategoryName = AppMetadata.defaultCategoryDirectoryName
      selectedCardID = nil
    }

    if shouldFocusNewCard {
      applySelectedCardText()
      draftSession.begin(card: selectedCard)
      editorFocusRevision += 1
    } else if let selectedCardID, !cards.contains(where: { $0.id == selectedCardID }) {
      self.selectedCardID = nil
      applySelectedCardText()
      draftSession.begin(card: nil)
    } else {
      applySelectedCardText()
    }

    refreshPreview()
  }

  fileprivate func showSelectedCategory() {
    if let selectedCardID,
      categoryCards.contains(where: { $0.id == selectedCardID })
    {
      // keep current selection
    } else {
      selectedCardID = categoryCards.first?.id
    }
    applySelectedCardText()
    draftSession.begin(card: selectedCard)
    refreshPreview()
  }

  fileprivate func applySelectedCardText() {
    editorText = selectedCard?.body ?? ""
  }

  @discardableResult
  fileprivate func flushDraft() -> Bool {
    switch draftSession.flush(against: cards) {
    case .noChange:
      return true
    case .saved(let card):
      if let index = cards.firstIndex(where: { $0.id == card.id }) {
        cards[index] = card
      }
      return true
    case .failure:
      return false
    }
  }

  fileprivate func makeCategoryItems(cards: [MemoryCard]) throws -> [CardCategoryItem] {
    CardCategoryList.items(
      directories: try memoryCardRepository.listDirectories(),
      cards: cards)
  }
}
