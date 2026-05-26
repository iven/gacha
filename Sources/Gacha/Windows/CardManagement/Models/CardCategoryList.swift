import Foundation

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
