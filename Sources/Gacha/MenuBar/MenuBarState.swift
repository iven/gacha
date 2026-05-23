import Foundation

struct MenuBarState {
  var isPaused = false

  var pauseDisplayTitle: String {
    isPaused ? MenuBarStrings.resumeDisplay : MenuBarStrings.pauseDisplay
  }
}
