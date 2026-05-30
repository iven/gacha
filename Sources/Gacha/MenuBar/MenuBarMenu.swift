import SwiftUI

struct MenuBarMenu: View {
  @ObservedObject var viewModel: MenuBarViewModel
  let onOpenCards: () -> Void
  let onOpenSettings: () -> Void

  var body: some View {
    Button(viewModel.isPaused ? MenuBarStrings.resumeDisplay : MenuBarStrings.pauseDisplay) {
      viewModel.onTogglePause?(!viewModel.isPaused)
    }
    Button(MenuBarStrings.cards) {
      onOpenCards()
    }
    Button(MenuBarStrings.settings) {
      onOpenSettings()
    }
    .keyboardShortcut(",", modifiers: .command)
    Divider()
    Button(MenuBarStrings.quit) {
      NSApplication.shared.terminate(nil)
    }
    .keyboardShortcut("q", modifiers: .command)
  }
}
