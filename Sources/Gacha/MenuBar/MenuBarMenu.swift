import SwiftUI

struct MenuBarMenu: View {
  @ObservedObject var viewModel: MenuBarViewModel

  var body: some View {
    Button(viewModel.isPaused ? MenuBarStrings.resumeDisplay : MenuBarStrings.pauseDisplay) {
      viewModel.onTogglePause?(!viewModel.isPaused)
    }
    Button(MenuBarStrings.cards) {
      viewModel.onOpenCards?()
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
