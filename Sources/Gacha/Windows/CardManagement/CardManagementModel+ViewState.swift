import Foundation

// View-facing projections of `CardManagementModel`: read-only derived state the
// SwiftUI views observe, plus the routing enums for sheets and alerts. These do
// not mutate model state, so they live apart from the core state machine.
extension CardManagementModel {
  // MARK: - Derived state

  var selectedCard: MemoryCard? {
    guard let selectedCardID else {
      return nil
    }

    return cards.first { $0.id == selectedCardID }
  }

  var existingCategoryDirectories: [String] {
    categories.map(\.directory)
  }

  var selectedCategory: CardCategoryItem? {
    categories.first { $0.directory == selectedDirectory }
  }

  var categoryCards: [MemoryCard] {
    cards.filter { $0.directory == selectedDirectory }
  }

  /// Categories a card can be moved into (everything except its current one).
  func moveTargets(for card: MemoryCard) -> [CardCategoryItem] {
    categories.filter { $0.directory != card.directory }
  }

  func isUserCategory(_ category: CardCategoryItem) -> Bool {
    category.directory != AppMetadata.defaultCategoryDirectoryName
  }

  // MARK: - Routing

  /// Sheet routed through `CardManagementView`'s `.sheet(item:)`.
  enum ActiveSheet: Identifiable {
    case newCategory
    case renameCategory(CardCategoryItem)

    var id: String {
      switch self {
      case .newCategory:
        return "newCategory"
      case .renameCategory(let category):
        return "rename.\(category.directory)"
      }
    }
  }

  /// Destructive confirmation routed through `CardManagementView`'s `.alert(item:)`.
  enum PendingDeletion: Identifiable {
    case card(MemoryCard)
    case category(CardCategoryItem)

    var id: String {
      switch self {
      case .card(let card):
        return "card.\(card.id)"
      case .category(let category):
        return "category.\(category.directory)"
      }
    }
  }
}
