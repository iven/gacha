import Foundation

@MainActor
final class NotchAutoCollapseSchedule: ObservableObject {
  struct Active: Equatable {
    let start: Date
    let duration: TimeInterval
  }

  @Published private(set) var active: Active?

  func start(duration: TimeInterval) {
    active = Active(start: Date(), duration: duration)
  }

  func clear() {
    active = nil
  }
}
