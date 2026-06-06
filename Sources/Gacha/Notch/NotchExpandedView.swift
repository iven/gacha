import SwiftUI

struct NotchExpandedView: View {
  @ObservedObject var coordinator: NotchPresentationCoordinator
  let autoCollapseSchedule: NotchAutoCollapseSchedule

  var body: some View {
    switch coordinator.surface {
    case .memory:
      MemoryNotchExpandedView(
        presenter: coordinator.memoryPresenter,
        autoCollapseSchedule: autoCollapseSchedule)
    }
  }
}
