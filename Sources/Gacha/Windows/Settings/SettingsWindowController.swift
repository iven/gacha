import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
  var onWindowDidClose: (() -> Void)?

  private let directories: AppDirectories
  private let launchAtLoginController: LaunchAtLoginController
  private let settingsStore: SettingsStore
  private(set) var window: NSWindow?

  init(
    directories: AppDirectories,
    launchAtLoginController: LaunchAtLoginController,
    settingsStore: SettingsStore
  ) {
    self.directories = directories
    self.launchAtLoginController = launchAtLoginController
    self.settingsStore = settingsStore
    super.init()
  }

  func show() {
    let window = self.window ?? makeWindow()
    self.window = window
    window.makeKeyAndOrderFront(nil)
  }

  private func makeWindow() -> NSWindow {
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
      rootView: SettingsView(
        directories: directories,
        launchAtLoginController: launchAtLoginController,
        settingsStore: settingsStore))
    window.center()
    return window
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    sender.orderOut(nil)
    onWindowDidClose?()
    return false
  }
}
