import SwiftUI

struct IntegrationsSettingsTab: View {
  @ObservedObject var environment: AppEnvironment
  let settingsStore: SettingsStore

  var body: some View {
    Form {
      MCPSettingsSection(environment: environment, settingsStore: settingsStore)
      CLISettingsSection(environment: environment)
    }
    .formStyle(.grouped)
  }
}
