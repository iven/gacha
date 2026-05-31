import SwiftUI

struct GeneralSettingsTab: View {
  let launchAtLoginController: LaunchAtLoginController
  let settingsStore: SettingsStore
  let suppressionController: SuppressionController

  @State private var launchAtLoginEnabled: Bool
  @State private var memoryAutoCollapseSeconds: TimeInterval
  @State private var skipCountdownOnAnotherWindow: Bool
  @State private var showKeyboardHints: Bool
  @State private var fullScreenSuppressionEnabled: Bool
  @State private var screenSharingSuppressionEnabled: Bool

  init(
    launchAtLoginController: LaunchAtLoginController,
    settingsStore: SettingsStore,
    suppressionController: SuppressionController
  ) {
    self.launchAtLoginController = launchAtLoginController
    self.settingsStore = settingsStore
    self.suppressionController = suppressionController
    _launchAtLoginEnabled = State(initialValue: settingsStore.launchAtLoginEnabled)
    _memoryAutoCollapseSeconds = State(
      initialValue: settingsStore.memoryAutoCollapseSeconds)
    _skipCountdownOnAnotherWindow = State(
      initialValue: settingsStore.skipCountdownOnAnotherWindow)
    _showKeyboardHints = State(initialValue: settingsStore.showKeyboardHints)
    _fullScreenSuppressionEnabled = State(
      initialValue: settingsStore.fullScreenSuppressionEnabled)
    _screenSharingSuppressionEnabled = State(
      initialValue: settingsStore.screenSharingSuppressionEnabled)
  }

  var body: some View {
    Form {
      Section(SettingsStrings.sectionStartup) {
        Toggle(
          SettingsStrings.launchAtLogin,
          isOn: Binding(
            get: { launchAtLoginEnabled },
            set: { setLaunchAtLoginEnabled($0) }))
      }

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
      }

      Section(SettingsStrings.sectionMemoryCards) {
        LabeledContent(SettingsStrings.collapseCountdown) {
          HStack(spacing: 8) {
            Slider(
              value: Binding(
                get: { memoryAutoCollapseSeconds },
                set: { newValue in
                  memoryAutoCollapseSeconds = newValue
                  settingsStore.memoryAutoCollapseSeconds = newValue
                }),
              in: SettingsStore.memoryAutoCollapseRange,
              step: SettingsStore.memoryAutoCollapseStep)
            Text("\(Int(memoryAutoCollapseSeconds))\(SettingsStrings.collapseCountdownUnit)")
              .foregroundStyle(.secondary)
              .monospacedDigit()
              .frame(width: 36, alignment: .trailing)
          }
        }
      }
    }
    .formStyle(.grouped)
    .scrollDisabled(true)
    .frame(width: 520)
    .fixedSize(horizontal: false, vertical: true)
  }

  private func setLaunchAtLoginEnabled(_ enabled: Bool) {
    launchAtLoginEnabled = enabled
    settingsStore.launchAtLoginEnabled = enabled

    do {
      let status = try launchAtLoginController.synchronize(enabled: enabled)
      if enabled && status == .requiresApproval {
        launchAtLoginController.openSystemSettingsLoginItems()
      }
    } catch {
      AppLogger.app.warning("Failed to synchronize launch at login: \(error.localizedDescription)")
    }
  }
}
