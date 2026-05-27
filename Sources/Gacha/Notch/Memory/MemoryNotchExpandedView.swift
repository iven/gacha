import SwiftUI

struct MemoryNotchExpandedView: View {
  @ObservedObject var presenter: MemoryNotchPresenter

  var body: some View {
    switch presenter.currentCard {
    case let memoryCard as MemoryCard:
      MemoryCardExpandedView(
        card: memoryCard,
        actions: presenter.actions,
        isInteractive: presenter.isInteractive)
    default:
      EmptyStateExpandedView(action: presenter.actions.onNewCard)
    }
  }
}
