import SwiftUI

@MainActor
final class NotchIdleReminderState: ObservableObject {
  @Published private(set) var triggerID = 0
  @Published var isSuppressed = false
  private(set) var pulseCount = 5

  func trigger(pulseCount: Int) {
    self.pulseCount = pulseCount
    triggerID += 1
  }
}
