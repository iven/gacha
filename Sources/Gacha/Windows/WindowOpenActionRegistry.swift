import AppKit

@MainActor
final class WindowOpenActionRegistry {
  private var openers: [AppWindowKey: () -> Void] = [:]
  private var windows: [AppWindowKey: WeakWindow] = [:]
  private var pendingOpenKeys = Set<AppWindowKey>()

  func register(_ key: AppWindowKey, opener: @escaping () -> Void) {
    openers[key] = opener
    if pendingOpenKeys.remove(key) != nil {
      opener()
    }
  }

  func registerWindow(_ key: AppWindowKey, window: NSWindow?) {
    guard let window else {
      windows[key] = nil
      return
    }
    windows[key] = WeakWindow(window)
  }

  func open(_ key: AppWindowKey) {
    if bringRegisteredWindowToFront(key) {
      return
    }

    guard let opener = openers[key] else {
      pendingOpenKeys.insert(key)
      return
    }
    opener()
  }

  private func bringRegisteredWindowToFront(_ key: AppWindowKey) -> Bool {
    guard let window = windows[key]?.window else {
      windows[key] = nil
      return false
    }

    if window.isMiniaturized {
      window.deminiaturize(nil)
    }
    NSApp.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
    return true
  }
}

private final class WeakWindow {
  weak var window: NSWindow?

  init(_ window: NSWindow) {
    self.window = window
  }
}
