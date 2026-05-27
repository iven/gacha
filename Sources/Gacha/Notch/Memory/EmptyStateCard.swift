import Foundation

struct EmptyStateCard: Card, Equatable {
  let kind: CardKind = .emptyState

  func autoCollapseTimeout(memoryAutoCollapseSeconds: TimeInterval) -> Duration? {
    .zero
  }
}
