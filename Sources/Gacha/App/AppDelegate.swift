import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var environment: AppEnvironment?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    environment = AppBootstrapper().bootstrap()
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }
}
