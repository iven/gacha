import Foundation

struct MemoryCardDTO: Encodable {
  let id: String
  let body: String
  let category: String
  let due: Date?
  let createdAt: Date
  let updatedAt: Date

  init(_ card: MemoryCard) {
    id = card.id
    body = card.body
    category = card.directory
    due = card.due
    createdAt = card.createdAt
    updatedAt = card.updatedAt
  }
}
