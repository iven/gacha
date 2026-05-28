import SwiftUI

struct SettingsView: View {
  let directories: AppDirectories
  let launchAtLoginController: LaunchAtLoginController
  let settingsStore: SettingsStore
  @State private var launchAtLoginEnabled: Bool
  @State private var memoryAutoCollapseSeconds: TimeInterval
  @State private var skipCountdownOnAnotherWindow: Bool
  @State private var showKeyboardHints: Bool

  init(
    directories: AppDirectories,
    launchAtLoginController: LaunchAtLoginController,
    settingsStore: SettingsStore
  ) {
    self.directories = directories
    self.launchAtLoginController = launchAtLoginController
    self.settingsStore = settingsStore
    _launchAtLoginEnabled = State(initialValue: settingsStore.launchAtLoginEnabled)
    _memoryAutoCollapseSeconds = State(
      initialValue: settingsStore.memoryAutoCollapseSeconds)
    _skipCountdownOnAnotherWindow = State(
      initialValue: settingsStore.skipCountdownOnAnotherWindow)
    _showKeyboardHints = State(initialValue: settingsStore.showKeyboardHints)
  }

  var body: some View {
    Form {
      Section(SettingsStrings.sectionStorage) {
        LabeledContent(SettingsStrings.storageLocation) {
          Text(directories.userStorageURL.path)
            .lineLimit(1)
            .truncationMode(.middle)
            .textSelection(.enabled)
            .foregroundStyle(.secondary)
        }
      }

      Section(SettingsStrings.sectionGeneral) {
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
      }

      Section(SettingsStrings.sectionMemoryCards) {
        LabeledContent(SettingsStrings.collapseCountdown) {
          HStack(spacing: 6) {
            TextField(
              "",
              value: Binding(
                get: { Int(memoryAutoCollapseSeconds) },
                set: { newValue in
                  let clamped = TimeInterval(
                    min(
                      max(newValue, Int(SettingsStore.memoryAutoCollapseRange.lowerBound)),
                      Int(SettingsStore.memoryAutoCollapseRange.upperBound)))
                  memoryAutoCollapseSeconds = clamped
                  settingsStore.memoryAutoCollapseSeconds = clamped
                }),
              format: .number
            )
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .frame(width: 56)
            Stepper(
              "",
              value: Binding(
                get: { memoryAutoCollapseSeconds },
                set: { newValue in
                  memoryAutoCollapseSeconds = newValue
                  settingsStore.memoryAutoCollapseSeconds = newValue
                }),
              in: SettingsStore.memoryAutoCollapseRange,
              step: SettingsStore.memoryAutoCollapseStep
            )
            .labelsHidden()
            Text(SettingsStrings.collapseCountdownUnit)
              .foregroundStyle(.secondary)
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
