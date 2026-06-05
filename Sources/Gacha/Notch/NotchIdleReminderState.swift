import SwiftUI

@MainActor
final class NotchIdleReminderState: ObservableObject {
  @Published private(set) var triggerID = 0
  @Published var isSuppressed = false
  private(set) var pulseCount = 5

  // The compact view records the trigger it last animated here rather than in
  // @State, so the progress survives the view being torn down and rebuilt on
  // every expand/compact cycle instead of replaying on each reappearance.
  var handledTriggerID = 0

  func trigger(pulseCount: Int) {
    self.pulseCount = pulseCount
    triggerID += 1
  }
}
