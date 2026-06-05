import Foundation

struct EmptyStateCard: Card, Equatable {
  let kind: CardKind = .emptyState

  func autoCollapseTimeout(memoryCardAutoCollapseSeconds: TimeInterval) -> Duration? {
    .zero
  }
}
