import AppKit

/// Self-relaunch via a short-lived shell helper that waits, then asks
/// LaunchServices to start a new instance.
///
/// Prefers `open -n -b <bundle-id>` when running from a real .app bundle
/// (production); falls back to `open -n <executablePath>` when running via
/// `swift run` during development, since LaunchServices won't have a bundle
/// id to look up.
@MainActor
enum AppRelauncher {
  static func relaunchAndQuit(delay seconds: Double = 0.3) {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/sh")

    if Bundle.main.bundleURL.pathExtension == "app" {
      task.arguments = [
        "-c",
        "sleep \(seconds); exec /usr/bin/open -n -b \"$0\"",
        AppMetadata.bundleIdentifier,
      ]
    } else {
      let executable = Bundle.main.executablePath ?? CommandLine.arguments[0]
      task.arguments = [
        "-c",
        "sleep \(seconds); nohup \"$0\" >/dev/null 2>&1 &",
        executable,
      ]
    }

    do {
      try task.run()
    } catch {
      AppLogger.app.warning("Failed to spawn relauncher: \(error.localizedDescription)")
    }
    NSApp.terminate(nil)
  }
}
