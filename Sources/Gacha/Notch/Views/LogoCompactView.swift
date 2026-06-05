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
  @State private var reminderAnimating = false
  @State private var reminderPulse = false
  @State private var handledTriggerID = 0

  var body: some View {
    ZStack {
      Capsule()
        .fill(.red)
        .opacity(isReminderVisible ? pulseAmount * 0.2 : 0)

      Capsule()
        .strokeBorder(.red, lineWidth: 1)
        .scaleEffect(1 + pulseAmount * 0.05)
        .opacity(isReminderVisible ? pulseAmount * 0.2 : 0)

      Text("G")
        .font(.custom("Avenir-Black", size: NotchToolbarStyle.compactGlyphFontSize))
        .foregroundStyle(LogoCompactView.gFill)
        .scaleEffect(isReminderVisible ? 1 + pulseAmount * 0.16 : 1)
        .opacity(0.8 + (isReminderVisible ? pulseAmount * 0.2 : 0))
        .shadow(color: .white.opacity(isReminderVisible ? pulseAmount * 0.6 : 0), radius: 3)
    }
    .notchToolbarControl()
    .onAppear {
      handleTrigger(idleReminderState.triggerID)
    }
    .onChange(of: idleReminderState.triggerID) { _, triggerID in
      handleTrigger(triggerID)
    }
  }

  private var isReminderVisible: Bool {
    reminderAnimating && !idleReminderState.isSuppressed
  }

  private var pulseAmount: Double {
    reminderPulse ? 1 : 0
  }

  private func playReminderAnimation() {
    reminderPulse = false
    reminderAnimating = true
    Task { @MainActor in
      for _ in 0..<idleReminderState.pulseCount {
        withAnimation(.easeInOut(duration: 0.55)) {
          reminderPulse = true
        }
        try? await Task.sleep(for: .seconds(0.55))
        withAnimation(.easeInOut(duration: 0.55)) {
          reminderPulse = false
        }
        try? await Task.sleep(for: .seconds(0.55))
      }
      reminderAnimating = false
    }
  }

  private func handleTrigger(_ triggerID: Int) {
    guard triggerID != handledTriggerID else {
      return
    }
    handledTriggerID = triggerID
    playReminderAnimation()
  }
}
