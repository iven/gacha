import AppKit
import SwiftUI

@MainActor
final class WindowCoordinator {
  private let directories: AppDirectories
  private var settingsWindow: NSWindow?

  init(directories: AppDirectories) {
    self.directories = directories
  }

  func openSettings() {
    let window = settingsWindow ?? makeSettingsWindow()
    settingsWindow = window
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  private func makeSettingsWindow() -> NSWindow {
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 560, height: 360),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false)
    window.title = SettingsStrings.windowTitle
    window.collectionBehavior = [.auxiliary]
    window.contentViewController = NSHostingController(
      rootView: SettingsView(directories: directories))
    window.center()
    return window
  }
}
