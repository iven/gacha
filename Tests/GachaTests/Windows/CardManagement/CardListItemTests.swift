import Foundation
import Testing

@testable import Gacha

@Test(arguments: [
  ("", CardManagementStrings.emptyCardSummary),
  ("Title", CardManagementStrings.emptyCardSummary),
  ("Title\n  \n\t", CardManagementStrings.emptyCardSummary),
  ("Title\r\n\rSecond line", "Second line"),
])
func cardListItemSummaryHandlesBodyBoundaries(body: String, expectedSummary: String) {
  #expect(CardListItem.summary(for: body) == expectedSummary)
}

@Test func cardListItemSubtitleUsesFoundationNewlineBoundaries() {
  let card = MemoryCard(
    id: "20260523-150944-k7x4q9",
    body: "Title\r\n\rSecond line",
    directory: "Uncategorized",
    due: nil,
    stability: nil,
    difficulty: nil,
    lastSeen: nil,
    createdAt: Date(timeIntervalSince1970: 1_779_548_984),
    updatedAt: Date(timeIntervalSince1970: 1_779_548_984))

  let subtitle = CardListItem(card: card).subtitle

  #expect(subtitle.contains("Second line"))
  #expect(!subtitle.contains("\r"))
}
