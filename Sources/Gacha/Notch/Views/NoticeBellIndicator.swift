import SwiftUI

struct NoticeBellIndicator: View {
  let pulseTriggerID: Int
  let handledPulseTriggerID: Binding<Int>?

  init(
    pulseTriggerID: Int,
    handledPulseTriggerID: Binding<Int>? = nil
  ) {
    self.pulseTriggerID = pulseTriggerID
    self.handledPulseTriggerID = handledPulseTriggerID
  }

  var body: some View {
    NotchAnimatedCue(
      triggerID: pulseTriggerID,
      pulseCount: 5,
      restingShell: true,
      fill: .ambient(AnyShapeStyle(.red)),
      restingContentGlowAmount: 1,
      externalHandledTriggerID: handledPulseTriggerID
    ) { pulseAmount in
      Image(systemName: "bell.fill")
        .font(.system(size: NotchToolbarStyle.compactGlyphFontSize, weight: .bold))
        .foregroundStyle(.white.opacity(0.85 + pulseAmount * 0.15))
    }
  }
}
