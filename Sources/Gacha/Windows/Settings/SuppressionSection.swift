import SwiftUI

struct SuppressionSection: View {
  let settingsStore: SettingsStore
  let suppressionController: SuppressionController

  @State private var fullScreenSuppressionEnabled: Bool
  @State private var screenSharingSuppressionEnabled: Bool
  @State private var focusModeSuppressionEnabled: Bool

  init(settingsStore: SettingsStore, suppressionController: SuppressionController) {
    self.settingsStore = settingsStore
    self.suppressionController = suppressionController
    _fullScreenSuppressionEnabled = State(
      initialValue: settingsStore.fullScreenSuppressionEnabled)
    _screenSharingSuppressionEnabled = State(
      initialValue: settingsStore.screenSharingSuppressionEnabled)
    _focusModeSuppressionEnabled = State(
      initialValue: settingsStore.focusModeSuppressionEnabled)
  }

  var body: some View {
    Section(SettingsStrings.sectionSuppression) {
      Toggle(
        SettingsStrings.fullScreenSuppressionEnabled,
        isOn: Binding(
          get: { fullScreenSuppressionEnabled },
          set: { newValue in
            fullScreenSuppressionEnabled = newValue
            settingsStore.fullScreenSuppressionEnabled = newValue
            suppressionController.reevaluate()
          }))

      Toggle(
        SettingsStrings.screenSharingSuppressionEnabled,
        isOn: Binding(
          get: { screenSharingSuppressionEnabled },
          set: { newValue in
            screenSharingSuppressionEnabled = newValue
            settingsStore.screenSharingSuppressionEnabled = newValue
            suppressionController.reevaluate()
          }))

      Toggle(
        isOn: Binding(
          get: { focusModeSuppressionEnabled },
          set: { newValue in
            focusModeSuppressionEnabled = newValue
            settingsStore.focusModeSuppressionEnabled = newValue
            suppressionController.reevaluate()
          })
      ) {
        VStack(alignment: .leading, spacing: 2) {
          Text(SettingsStrings.focusModeSuppressionEnabled)
          Text(SettingsStrings.focusModeSuppressionHint)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }
}
