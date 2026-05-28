import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  static private(set) var shared: AppDelegate?
  static let menuBarViewModel = MenuBarViewModel()
  private(set) var environment: AppEnvironment?

  override init() {
    super.init()
    AppDelegate.shared = self
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    do {
      environment = try AppBootstrapper().bootstrap()
    } catch {
      AppLogger.app.error("Failed to start app: \(error.localizedDescription)")
      presentStartupFailure(error)
      NSApp.terminate(nil)
    }
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }

  private func presentStartupFailure(_ error: Error) {
    NSApp.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: true)

    let alert = NSAlert()
    alert.alertStyle = .critical
    alert.messageText = AppStartupStrings.failureTitle
    alert.informativeText = AppStartupStrings.failureMessage(
      errorDescription: error.localizedDescription)
    alert.addButton(withTitle: AppStartupStrings.failureQuit)
    alert.runModal()
  }
}
