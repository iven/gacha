import SwiftUI

struct AutoCollapseProgressBar: View {
  @ObservedObject var schedule: NotchAutoCollapseSchedule

  static let height: CGFloat = 1

  var body: some View {
    TimelineView(.animation) { context in
      let remaining = currentRemaining(at: context.date)
      Capsule(style: .continuous)
        .fill(color(for: remaining))
        .frame(height: Self.height)
        .scaleEffect(x: remaining, y: 1, anchor: .center)
        .frame(maxWidth: .infinity, alignment: .center)
    }
  }

  private func currentRemaining(at date: Date) -> Double {
    guard let active = schedule.active, active.duration > 0 else {
      return 1
    }
    let elapsed = date.timeIntervalSince(active.start)
    let padded = active.duration + min(active.duration * 0.1, 1)
    return max(0, 1 - elapsed / padded)
  }

  private func color(for remaining: Double) -> Color {
    let progress = 1 - remaining
    return Color(
      red: 1.0,
      green: 1.0 - progress * 0.7,
      blue: 1.0 - progress * 0.6
    ).opacity(0.2 + progress * 0.8)
  }
}
