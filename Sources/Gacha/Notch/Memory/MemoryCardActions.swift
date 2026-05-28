import Foundation

struct MemoryCardActions {
  let isDue: (MemoryCard) -> Bool
  let onRate: (MemoryCard, MemoryCardRating) -> Void
  let onNext: (MemoryCard) -> Void
  let onNewCard: () -> Void
  let onEditCard: (MemoryCard) -> Void
  let onDismiss: () -> Void
}
