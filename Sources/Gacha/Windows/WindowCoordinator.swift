import AppKit
import SwiftUI

@MainActor
final class WindowCoordinator: NSObject, NSWindowDelegate {
  private let directories: AppDirectories
  private let settingsStore: SettingsStore
  private var settingsWindow: NSWindow?

  init(directories: AppDirectories, settingsStore: SettingsStore) {
    self.directories = directories
    self.settingsStore = settingsStore
    super.init()
  }

  func openSettings() {
    NSApp.setActivationPolicy(.regular)
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
    window.isReleasedWhenClosed = false
    window.title = SettingsStrings.windowTitle
    window.collectionBehavior = [.auxiliary]
    window.delegate = self
    window.contentViewController = NSHostingController(
      rootView: SettingsView(directories: directories, settingsStore: settingsStore))
    window.center()
    return window
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    sender.orderOut(nil)
    NSApp.setActivationPolicy(.accessory)
    return false
  }
}
