import AppKit

@MainActor
struct MenuBarActions {
  var openNewCard: () -> Void
  var openSettings: () -> Void
  var setPaused: (Bool) -> Void
  var quit: () -> Void

  static let live = MenuBarActions(
    openNewCard: {},
    openSettings: {},
    setPaused: { _ in },
    quit: {
      NSApp.terminate(nil)
    })
}
