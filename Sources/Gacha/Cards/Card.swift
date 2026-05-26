import Foundation

enum CardKind: String, Equatable {
  case memory
  case emptyState
  case notice
}

protocol Card {
  var kind: CardKind { get }
  func autoCollapseTimeout(memoryAutoCollapseSeconds: TimeInterval) -> Duration?
}
