import Foundation

struct MemoryCard: Card, Equatable, Identifiable {
  let kind: CardKind = .memory
  var id: String
  var title: String
  var body: String
  var directory: String
  var due: Date?
  var stability: Double?
  var difficulty: Double?
  var lastSeen: Date?
  var createdAt: Date
}

extension MemoryCard {
  var relativeFilePath: String {
    "\(directory)/\(id).md"
  }
}
