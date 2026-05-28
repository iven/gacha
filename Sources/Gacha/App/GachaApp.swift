import SwiftUI

@main
struct GachaApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    MenuBarExtra(AppMetadata.name) {
      MenuBarRootView()
    }

    Settings {
      SettingsRootView()
    }
  }
}

private struct MenuBarRootView: View {
  @ObservedObject private var viewModel = AppDelegate.menuBarViewModel

  var body: some View {
    MenuBarMenu(viewModel: viewModel)
  }
}

private struct SettingsRootView: View {
  var body: some View {
    Group {
      if let environment = AppDelegate.shared?.environment {
        SettingsView(
          directories: environment.directories,
          launchAtLoginController: environment.launchAtLoginController,
          settingsStore: environment.settingsStore,
          storageRelocationCoordinator: environment.storageRelocationCoordinator)
      } else {
        ProgressView()
      }
    }
    .onAppear { AppDelegate.shared?.environment?.onSettingsVisibilityChange(true) }
    .onDisappear { AppDelegate.shared?.environment?.onSettingsVisibilityChange(false) }
  }
}
