import SwiftUI

struct MemoryNotchExpandedView: View {
  @ObservedObject var presenter: MemoryNotchPresenter
  let autoCollapseSchedule: NotchAutoCollapseSchedule

  var body: some View {
    switch presenter.currentCard {
    case let memoryCard as MemoryCard:
      MemoryCardExpandedView(
        card: memoryCard,
        actions: presenter.actions,
        isInteractive: presenter.isInteractive,
        showKeyboardHints: presenter.showKeyboardHints,
        autoCollapseSchedule: autoCollapseSchedule)
    default:
      EmptyStateExpandedView(action: presenter.actions.onNewCard)
    }
  }
}
