import AppKit

@MainActor
struct MenuBarActions {
  var openCards: () -> Void
  var openSettings: () -> Void
  var setPaused: (Bool) -> Void
  var quit: () -> Void

  static let live = MenuBarActions(
    openCards: {},
    openSettings: {},
    setPaused: { _ in },
    quit: {
      NSApp.terminate(nil)
    })
}
