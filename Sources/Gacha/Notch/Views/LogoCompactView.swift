import SwiftUI

struct LogoCompactView: View {
  private let idleReminderState: NotchIdleReminderState?

  // Mirrors icon.json's G-avenir gradient: rose at top, fully white at y=0.72.
  static let gFill = LinearGradient(
    stops: [
      .init(color: Color(red: 1.0, green: 0.353, blue: 0.401), location: 0),
      .init(color: Color(red: 1.0, green: 0.863, blue: 0.84), location: 0.72),
    ],
    startPoint: .top,
    endPoint: .bottom
  )

  // A nil state means the caller only wants the static glyph (e.g. the expanded
  // view), with no reminder cadence to observe.
  init(idleReminderState: NotchIdleReminderState? = nil) {
    self.idleReminderState = idleReminderState
  }

  var body: some View {
    if let idleReminderState {
      IdleReminderLogoView(idleReminderState: idleReminderState)
    } else {
      Text("G")
        .font(.custom("Avenir-Black", size: NotchToolbarStyle.compactGlyphFontSize))
        .foregroundStyle(Self.gFill)
        .opacity(0.8)
        .notchToolbarControl()
    }
  }
}

private struct IdleReminderLogoView: View {
  @ObservedObject var idleReminderState: NotchIdleReminderState

  var body: some View {
    NotchAnimatedCue(
      triggerID: idleReminderState.triggerID,
      pulseCount: idleReminderState.pulseCount,
      isSuppressed: idleReminderState.isSuppressed,
      restingShell: true,
      externalHandledTriggerID: Binding(
        get: { idleReminderState.handledTriggerID },
        set: { idleReminderState.handledTriggerID = $0 })
    ) { pulseAmount in
      Text("G")
        .font(.custom("Avenir-Black", size: NotchToolbarStyle.compactGlyphFontSize))
        .foregroundStyle(LogoCompactView.gFill)
        .opacity(0.8 + pulseAmount * 0.2)
    }
  }
}
