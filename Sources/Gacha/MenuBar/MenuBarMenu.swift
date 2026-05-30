import SwiftUI

struct MenuBarMenu: View {
  @ObservedObject var viewModel: MenuBarViewModel
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    Button(viewModel.isPaused ? MenuBarStrings.resumeDisplay : MenuBarStrings.pauseDisplay) {
      viewModel.onTogglePause?(!viewModel.isPaused)
    }
    Button(MenuBarStrings.cards) {
      openWindow(id: GachaApp.cardWindowID)
    }
    SettingsLink {
      Text(MenuBarStrings.settings)
    }
    .keyboardShortcut(",", modifiers: .command)
    Divider()
    Button(MenuBarStrings.quit) {
      NSApplication.shared.terminate(nil)
    }
    .keyboardShortcut("q", modifiers: .command)
  }
}
