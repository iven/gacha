import SwiftUI

struct NotchSection: View {
  let settingsStore: SettingsStore
  let onIdleReminderTimeoutChanged: () -> Void

  private static let memoryCardAutoCollapsePresetSeconds = [
    0, 1, 2, 3, 5, 10, 15, 30, 60,
  ]
  private static let idleReminderAnimationPresetMinutes = [
    1, 2, 3, 5, 10, 20, 30, 60, 90, 120, 150, 180, 0,
  ]

  @State private var memoryCardAutoCollapseSeconds: Int
  @State private var idleReminderAnimationMinutes: Int
  @State private var skipAutoCollapseOnAnotherWindow: Bool
  @State private var showKeyboardHints: Bool

  init(settingsStore: SettingsStore, onIdleReminderTimeoutChanged: @escaping () -> Void) {
    self.settingsStore = settingsStore
    self.onIdleReminderTimeoutChanged = onIdleReminderTimeoutChanged
    _memoryCardAutoCollapseSeconds = State(
      initialValue: Int(settingsStore.memoryCardAutoCollapseSeconds))
    _idleReminderAnimationMinutes = State(
      initialValue: Int(settingsStore.idleReminderAnimationSeconds / 60))
    _skipAutoCollapseOnAnotherWindow = State(
      initialValue: settingsStore.skipAutoCollapseOnAnotherWindow)
    _showKeyboardHints = State(initialValue: settingsStore.showKeyboardHints)
  }

  var body: some View {
    Section(SettingsStrings.sectionNotch) {
      Toggle(
        SettingsStrings.showKeyboardHints,
        isOn: Binding(
          get: { showKeyboardHints },
          set: { newValue in
            showKeyboardHints = newValue
            settingsStore.showKeyboardHints = newValue
          }))

      Toggle(
        SettingsStrings.skipAutoCollapseOnAnotherWindow,
        isOn: Binding(
          get: { skipAutoCollapseOnAnotherWindow },
          set: { newValue in
            skipAutoCollapseOnAnotherWindow = newValue
            settingsStore.skipAutoCollapseOnAnotherWindow = newValue
          }))

      LabeledContent(SettingsStrings.memoryCardAutoCollapse) {
        Picker("", selection: memoryCardAutoCollapseSecondsBinding) {
          ForEach(Self.memoryCardAutoCollapsePresetSeconds, id: \.self) { seconds in
            Text(memoryCardAutoCollapseTitle(seconds))
              .tag(seconds)
          }
        }
        .labelsHidden()
        .pickerStyle(.menu)
      }

      LabeledContent(SettingsStrings.idleReminderAnimation) {
        Picker("", selection: idleReminderAnimationMinutesBinding) {
          ForEach(Self.idleReminderAnimationPresetMinutes, id: \.self) { minutes in
            Text(idleReminderAnimationMinuteTitle(minutes))
              .tag(minutes)
          }
        }
        .labelsHidden()
        .pickerStyle(.menu)
      }
    }
  }

  private var memoryCardAutoCollapseSecondsBinding: Binding<Int> {
    Binding(
      get: { memoryCardAutoCollapseSeconds },
      set: { newValue in
        settingsStore.memoryCardAutoCollapseSeconds = TimeInterval(newValue)
        memoryCardAutoCollapseSeconds = Int(settingsStore.memoryCardAutoCollapseSeconds)
      })
  }

  private func memoryCardAutoCollapseTitle(_ seconds: Int) -> String {
    if seconds == 0 {
      return SettingsStrings.memoryCardAutoCollapseImmediately
    }

    return "\(seconds) \(SettingsStrings.memoryCardAutoCollapseUnit)"
  }

  private func idleReminderAnimationMinuteTitle(_ minutes: Int) -> String {
    switch minutes {
    case 0:
      SettingsStrings.idleReminderAnimationNever
    case let minutes where minutes >= 60 && minutes.isMultiple(of: 60):
      "\(minutes / 60) \(SettingsStrings.idleReminderAnimationHourUnit)"
    case let minutes where minutes > 60:
      "\(minutes / 60) \(SettingsStrings.idleReminderAnimationHourUnit) "
        + "\(minutes % 60) \(SettingsStrings.idleReminderAnimationUnit)"
    default:
      "\(minutes) \(SettingsStrings.idleReminderAnimationUnit)"
    }
  }

  private var idleReminderAnimationMinutesBinding: Binding<Int> {
    Binding(
      get: { idleReminderAnimationMinutes },
      set: { newValue in
        settingsStore.idleReminderAnimationSeconds = TimeInterval(newValue * 60)
        idleReminderAnimationMinutes = Int(settingsStore.idleReminderAnimationSeconds / 60)
        onIdleReminderTimeoutChanged()
      })
  }
}
