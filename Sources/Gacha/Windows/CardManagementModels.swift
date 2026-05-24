import AppKit

struct CardCategoryItem {
  var directory: String
  var displayName: String
  var cardCount: Int
}

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

struct CardCategoryList {
  static func items(directories: [String], cards: [MemoryCard]) -> [CardCategoryItem] {
    var categoryDirectories = Set(directories)
    categoryDirectories.insert(AppMetadata.defaultCategoryDirectoryName)
    cards.forEach { categoryDirectories.insert($0.directory) }

    let counts = Dictionary(grouping: cards, by: \.directory).mapValues(\.count)
    return
      categoryDirectories
      .map { directory in
        CardCategoryItem(
          directory: directory,
          displayName: displayName(for: directory),
          cardCount: counts[directory, default: 0])
      }
      .sorted { lhs, rhs in
        if lhs.directory == AppMetadata.defaultCategoryDirectoryName {
          return true
        }
        if rhs.directory == AppMetadata.defaultCategoryDirectoryName {
          return false
        }

        return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
      }
  }

  private static func displayName(for directory: String) -> String {
    if directory == AppMetadata.defaultCategoryDirectoryName {
      return CardManagementStrings.uncategorized
    }

    return directory
  }
}

extension NSUserInterfaceItemIdentifier {
  static let categoryName = NSUserInterfaceItemIdentifier("Gacha.CardManagement.CategoryName")
  static let categoryCell = NSUserInterfaceItemIdentifier("Gacha.CardManagement.CategoryCell")
  static let cardTitle = NSUserInterfaceItemIdentifier("Gacha.CardManagement.CardTitle")
  static let cardCell = NSUserInterfaceItemIdentifier("Gacha.CardManagement.CardCell")
}
