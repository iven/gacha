import SwiftUI

struct SettingsView: View {
  let directories: AppDirectories
  let launchAtLoginController: LaunchAtLoginController
  let settingsStore: SettingsStore
  @State private var launchAtLoginEnabled: Bool
  @State private var memoryAutoCollapseSeconds: TimeInterval

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

        LabeledContent(SettingsStrings.autoCollapse) {
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
            Text(SettingsStrings.autoCollapseUnit)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .formStyle(.grouped)
    .scrollDisabled(true)
    .frame(width: 480)
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
