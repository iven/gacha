import SwiftUI

struct SettingsView: View {
  let directories: AppDirectories
  let launchAtLoginController: LaunchAtLoginController
  let settingsStore: SettingsStore
  let suppressionController: SuppressionController
  @ObservedObject var environment: AppEnvironment
  @ObservedObject var storageRelocationCoordinator: StorageRelocationCoordinator

  var body: some View {
    TabView {
      GeneralSettingsTab(
        launchAtLoginController: launchAtLoginController,
        settingsStore: settingsStore,
        suppressionController: suppressionController
      )
      .tabItem {
        Label(SettingsStrings.tabGeneral, systemImage: "gearshape")
      }

      IntegrationsSettingsTab(environment: environment, settingsStore: settingsStore)
        .tabItem {
          Label(SettingsStrings.tabIntegrations, systemImage: "puzzlepiece.extension")
        }

      AdvancedSettingsTab(
        directories: directories,
        storageRelocationCoordinator: storageRelocationCoordinator
      )
      .tabItem {
        Label(SettingsStrings.tabAdvanced, systemImage: "gearshape.2")
      }
    }
    .background(
      WindowAccessor { window in
        storageRelocationCoordinator.anchorWindow = window
      }
    )
  }
}
