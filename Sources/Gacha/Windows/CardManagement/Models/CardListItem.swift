import Foundation

struct CardListItem {
  var card: MemoryCard

  var displayTitle: String {
    let title = card.displayTitle
    return title.isEmpty ? CardManagementStrings.newCard : title
  }

  var subtitle: String {
    String(
      format: CardManagementStrings.cardListSubtitleFormat,
      Self.localizedDateFormatter.string(from: card.updatedAt),
      Self.summary(for: card.body))
  }

  static func summary(for body: String) -> String {
    let lines = body.components(separatedBy: .newlines).dropFirst()
    for line in lines {
      let summary = line.trimmingCharacters(in: .whitespacesAndNewlines)
      if !summary.isEmpty {
        return summary
      }
    }

    return CardManagementStrings.emptyCardSummary
  }

  private static let localizedDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
  }()
}
