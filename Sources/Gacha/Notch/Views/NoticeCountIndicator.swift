import SwiftUI

struct NoticeCountIndicator: View {
  let count: Int
  let pulseTriggerID: Int
  let handledPulseTriggerID: Binding<Int>?

  init(
    count: Int,
    pulseTriggerID: Int,
    handledPulseTriggerID: Binding<Int>? = nil
  ) {
    self.count = count
    self.pulseTriggerID = pulseTriggerID
    self.handledPulseTriggerID = handledPulseTriggerID
  }

  var body: some View {
    NotchAnimatedCue(
      triggerID: pulseTriggerID,
      pulseCount: 5,
      restingShell: false,
      showsShellWhileAnimating: true,
      externalHandledTriggerID: handledPulseTriggerID
    ) { pulseAmount in
      Text(formattedCount)
        .font(.custom("Avenir-Black", size: NotchToolbarStyle.compactGlyphFontSize))
        .foregroundStyle(.white.opacity(0.85 + pulseAmount * 0.15))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .contentTransition(.numericText(value: Double(count)))
    }
  }

  private var formattedCount: String {
    count > 99 ? "99+" : "\(count)"
  }
}
