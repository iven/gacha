import SwiftUI

struct NotchExpandedView: View {
  @ObservedObject var viewModel: NotchViewModel
  let actions: MemoryCardActions

  var body: some View {
    switch viewModel.currentCard {
    case let memoryCard as MemoryCard:
      MemoryCardExpandedView(card: memoryCard, actions: actions)
    default:
      EmptyStateExpandedView(action: actions.onNewCard)
    }
  }
}
