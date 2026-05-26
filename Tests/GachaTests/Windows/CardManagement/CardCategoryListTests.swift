import Foundation
import Testing

@testable import Gacha

@Test func cardCategoryListItemsSortDefaultCategoryFirstAndCountCards() {
  let items = CardCategoryList.items(
    directories: ["Beta", "Alpha"],
    cards: [
      makeCard(id: "20260523-150944-a1b2c3", body: "First", directory: "Beta"),
      makeCard(id: "20260523-150945-d4e5f6", body: "Second", directory: "Beta"),
      makeCard(id: "20260523-150946-g7h8i9", body: "Third", directory: "Gamma"),
    ])

  #expect(
    items.map(\.directory) == [
      AppMetadata.defaultCategoryDirectoryName,
      "Alpha",
      "Beta",
      "Gamma",
    ])
  #expect(items.map(\.cardCount) == [0, 0, 2, 1])
  #expect(items.first?.displayName == CardManagementStrings.uncategorized)
}

private func makeCard(
  id: String,
  body: String,
  directory: String
) -> MemoryCard {
  MemoryCard(
    id: id,
    body: body,
    directory: directory,
    due: nil,
    stability: nil,
    difficulty: nil,
    lastSeen: nil,
    createdAt: Date(timeIntervalSince1970: 1_779_548_984),
    updatedAt: Date(timeIntervalSince1970: 1_779_548_984))
}
