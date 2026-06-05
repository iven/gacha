import KeyboardShortcuts
import SwiftUI

struct ShortcutsSection: View {
  var body: some View {
    Section(SettingsStrings.sectionShortcuts) {
      KeyboardShortcuts.Recorder(
        SettingsStrings.shortcutToggleNotch, name: .toggleNotch)
    }
  }
}
