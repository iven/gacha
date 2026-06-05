import SwiftUI

struct StartupSection: View {
  let launchAtLoginController: LaunchAtLoginController
  let settingsStore: SettingsStore

  @State private var launchAtLoginEnabled: Bool

  init(launchAtLoginController: LaunchAtLoginController, settingsStore: SettingsStore) {
    self.launchAtLoginController = launchAtLoginController
    self.settingsStore = settingsStore
    _launchAtLoginEnabled = State(initialValue: settingsStore.launchAtLoginEnabled)
  }

  var body: some View {
    Section(SettingsStrings.sectionStartup) {
      Toggle(
        SettingsStrings.launchAtLogin,
        isOn: Binding(
          get: { launchAtLoginEnabled },
          set: { setLaunchAtLoginEnabled($0) }))
    }
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
