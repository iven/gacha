import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
  static private(set) var shared: AppDelegate?
  let windowOpenActionRegistry = WindowOpenActionRegistry()
  @Published private(set) var startupFailureMessage: String?
  private(set) var environment: AppEnvironment?

  override init() {
    super.init()
    AppDelegate.shared = self
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    do {
      environment = try AppBootstrapper(
        windowOpenActionRegistry: windowOpenActionRegistry
      ).bootstrap()
    } catch {
      AppLogger.app.error("Failed to start app: \(error.localizedDescription)")
      presentStartupFailure(error)
    }
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    false
  }

  private func presentStartupFailure(_ error: Error) {
    NSApp.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: true)

    startupFailureMessage = AppStartupStrings.failureMessage(
      errorDescription: error.localizedDescription)
  }
}
