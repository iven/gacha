import SwiftUI

@main
struct GachaApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    MenuBarExtra(AppMetadata.name) {
      MenuBarRootView()
    }

    Window(CardManagementStrings.windowTitle, id: GachaApp.cardWindowID) {
      CardManagementRootView()
    }
    .defaultSize(width: 960, height: 720)

    Settings {
      SettingsRootView()
    }
  }

  static let cardWindowID = "cards"
}

private struct MenuBarRootView: View {
  @ObservedObject private var viewModel = AppDelegate.menuBarViewModel

  var body: some View {
    MenuBarMenu(viewModel: viewModel)
  }
}

private struct CardManagementRootView: View {
  var body: some View {
    Group {
      if let environment = AppDelegate.shared?.environment {
        CardManagementView(model: environment.cardManagementModel)
          .environmentObject(environment.cardWindowBridge)
      } else {
        ProgressView()
      }
    }
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
