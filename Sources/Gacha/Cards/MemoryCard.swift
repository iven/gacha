import Foundation

struct MemoryCard: Card, Equatable, Identifiable {
  let kind: CardKind = .memory
  let autoCollapseTimeout: Duration? = nil
  var id: String
  var body: String
  var directory: String
  var due: Date?
  var stability: Double?
  var difficulty: Double?
  var lastSeen: Date?
  var createdAt: Date
  var updatedAt: Date
}

extension MemoryCard {
  var displayTitle: String {
    Self.displayTitle(for: body)
  }

  var relativeFilePath: String {
    "\(directory)/\(id).md"
  }

  static func displayTitle(for body: String) -> String {
    guard let firstLine = body.split(separator: "\n", omittingEmptySubsequences: false).first else {
      return ""
    }

    let trimmed = firstLine.trimmingCharacters(in: .whitespacesAndNewlines)
    guard
      let headingRange = trimmed.range(
        of: #"^#{1,6}\s+"#,
        options: .regularExpression
      )
    else {
      return trimmed
    }

    return String(trimmed[headingRange.upperBound...])
  }
}
