import SwiftUI

@main
struct GachaApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    MenuBarExtra {
      MenuBarRootView(windowOpenActionRegistry: appDelegate.windowOpenActionRegistry)
    } label: {
      Text(AppMetadata.name)
        .background(
          WindowOpenActionRegistrar(
            registry: appDelegate.windowOpenActionRegistry))
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
}

private struct MenuBarRootView: View {
  let windowOpenActionRegistry: WindowOpenActionRegistry
  @ObservedObject private var viewModel = AppDelegate.menuBarViewModel

  var body: some View {
    MenuBarMenu(
      viewModel: viewModel,
      onOpenCards: { windowOpenActionRegistry.open(.cards) },
      onOpenSettings: { windowOpenActionRegistry.open(.settings) })
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
