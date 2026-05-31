import Foundation

struct CardCategoryList {
  static func items(directories: [String], cards: [MemoryCard]) -> [CardCategoryItem] {
    var categoryNames = Set(directories)
    categoryNames.insert(AppMetadata.defaultCategoryDirectoryName)
    cards.forEach { categoryNames.insert($0.directory) }

    let counts = Dictionary(grouping: cards, by: \.directory).mapValues(\.count)
    return
      categoryNames
      .map { name in
        CardCategoryItem(
          name: name,
          displayName: displayName(for: name),
          cardCount: counts[name, default: 0])
      }
      .sorted { lhs, rhs in
        if lhs.name == AppMetadata.defaultCategoryDirectoryName {
          return true
        }
        if rhs.name == AppMetadata.defaultCategoryDirectoryName {
          return false
        }

        return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
      }
  }

  private static func displayName(for name: String) -> String {
    if name == AppMetadata.defaultCategoryDirectoryName {
      return CardManagementStrings.uncategorized
    }

    return name
  }
}
