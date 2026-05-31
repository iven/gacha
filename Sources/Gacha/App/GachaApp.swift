import SwiftUI

@main
struct GachaApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    Window("", id: GachaApp.windowBrokerID) {
      WindowBrokerView(windowOpenActionRegistry: appDelegate.windowOpenActionRegistry)
    }

    Window(CardManagementStrings.windowTitle, id: GachaApp.cardWindowID) {
      CardManagementRootView(windowOpenActionRegistry: appDelegate.windowOpenActionRegistry)
    }
    .defaultSize(width: 960, height: 720)

    Settings {
      SettingsRootView(windowOpenActionRegistry: appDelegate.windowOpenActionRegistry)
    }
  }

  static let cardWindowID = "cards"
  static let windowBrokerID = "window-broker"
}

private struct WindowBrokerView: View {
  let windowOpenActionRegistry: WindowOpenActionRegistry

  var body: some View {
    WindowOpenActionRegistrar(registry: windowOpenActionRegistry)
      .background(WindowAccessor { $0?.orderOut(nil) })
  }
}

private struct CardManagementRootView: View {
  let windowOpenActionRegistry: WindowOpenActionRegistry

  var body: some View {
    Group {
      if let environment = AppDelegate.shared?.environment {
        CardManagementView(model: environment.cardManagementModel)
          .environmentObject(environment.cardWindowBridge)
      } else {
        ProgressView()
      }
    }
    .background(
      WindowAccessor { window in
        if let window {
          windowOpenActionRegistry.registerWindow(.cards, window: window)
        }
      }
    )
  }
}

private struct SettingsRootView: View {
  let windowOpenActionRegistry: WindowOpenActionRegistry

  var body: some View {
    Group {
      if let environment = AppDelegate.shared?.environment {
        SettingsView(
          directories: environment.directories,
          launchAtLoginController: environment.launchAtLoginController,
          settingsStore: environment.settingsStore,
          suppressionController: environment.suppressionController,
          environment: environment,
          storageRelocationCoordinator: environment.storageRelocationCoordinator)
      } else {
        ProgressView()
      }
    }
    .background(
      WindowAccessor { window in
        if let window {
          windowOpenActionRegistry.registerWindow(.settings, window: window)
        }
      }
    )
    .onAppear { AppDelegate.shared?.environment?.onSettingsVisibilityChange(true) }
    .onDisappear {
      AppDelegate.shared?.environment?.onSettingsVisibilityChange(false)
    }
  }
}
