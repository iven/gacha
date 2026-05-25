import Foundation

struct EmptyStateCard: Card, Equatable {
  let kind: CardKind = .emptyState
  let autoCollapseTimeout: Duration? = .zero
}
