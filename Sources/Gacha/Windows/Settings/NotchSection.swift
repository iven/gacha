import SwiftUI

struct NotchSection: View {
  let settingsStore: SettingsStore

  @State private var memoryAutoCollapseSeconds: Int
  @State private var skipCountdownOnAnotherWindow: Bool
  @State private var showKeyboardHints: Bool

  init(settingsStore: SettingsStore) {
    self.settingsStore = settingsStore
    _memoryAutoCollapseSeconds = State(
      initialValue: Int(settingsStore.memoryAutoCollapseSeconds))
    _skipCountdownOnAnotherWindow = State(
      initialValue: settingsStore.skipCountdownOnAnotherWindow)
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
        SettingsStrings.skipCountdownOnAnotherWindow,
        isOn: Binding(
          get: { skipCountdownOnAnotherWindow },
          set: { newValue in
            skipCountdownOnAnotherWindow = newValue
            settingsStore.skipCountdownOnAnotherWindow = newValue
          }))

      LabeledContent(SettingsStrings.memoryCardCollapseCountdown) {
        HStack(spacing: 6) {
          TextField(
            "",
            value: memoryAutoCollapseSecondsBinding,
            format: .number.grouping(.never)
          )
          .frame(width: 48)
          .multilineTextAlignment(.trailing)

          Stepper(
            "",
            value: memoryAutoCollapseSecondsBinding,
            in: memoryAutoCollapseRange
          )
          .labelsHidden()

          Text(SettingsStrings.memoryCardCollapseCountdownUnit)
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private var memoryAutoCollapseSecondsBinding: Binding<Int> {
    Binding(
      get: { memoryAutoCollapseSeconds },
      set: { newValue in
        settingsStore.memoryAutoCollapseSeconds = TimeInterval(newValue)
        memoryAutoCollapseSeconds = Int(settingsStore.memoryAutoCollapseSeconds)
      })
  }

  private var memoryAutoCollapseRange: ClosedRange<Int> {
    let lowerBound = Int(SettingsStore.memoryAutoCollapseRange.lowerBound)
    let upperBound = Int(SettingsStore.memoryAutoCollapseRange.upperBound)
    return lowerBound...upperBound
  }
}
