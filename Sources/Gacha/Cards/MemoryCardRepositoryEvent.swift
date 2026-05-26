import Foundation

enum MemoryCardRepositoryEvent: Equatable {
  case didCreate(MemoryCard, focusEditor: Bool)
  case didUpdate(MemoryCard)
  case didDelete(id: String, directory: String)
  case didMoveDirectory(from: String, to: String)
  case didDeleteDirectory(name: String)
  case didRebuildIndex
}
