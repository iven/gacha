import Foundation
import os

/// Detects whether a macOS Focus mode (including the legacy Do Not Disturb) is
/// currently active, by listening for the distributed notifications
/// `_NSDoNotDisturbEnabledNotification` / `_NSDoNotDisturbDisabledNotification`.
/// macOS posts these the moment any Focus flips and Control Center listens to
/// the same pair, so the detector reacts at notification latency.
///
/// The detector never reads the on-disk Focus state. The only path that would
/// expose it (`~/Library/DoNotDisturb/DB/Assertions.json`) sits behind Full
/// Disk Access in modern macOS — wiring it up would force every user through a
/// privacy-tab grant just for a small UX gain. Instead, we accept that an
/// already-on Focus at launch goes undetected until the user toggles Focus
/// once; the surrounding settings UI advertises this caveat.
final class FocusModeDetector: SuppressionProbing, @unchecked Sendable {
  // Written once by `startReporting` (called on main from the controller)
  // and read once by `deinit`. Never accessed concurrently, so no lock.
  private var observers: [NSObjectProtocol] = []
  // Written from notification observers (registered with `queue: .main`),
  // read from `SuppressionController` (a `@MainActor`). The lock guards
  // this — and only this — so the `@unchecked Sendable` promise is real.
  private let cachedActive = OSAllocatedUnfairLock<Bool>(initialState: false)

  deinit {
    let center = DistributedNotificationCenter.default()
    for token in observers {
      center.removeObserver(token)
    }
  }

  func isSuppressingStateActive() -> Bool {
    cachedActive.withLock { $0 }
  }

  func startReporting(onChange: @escaping @Sendable () -> Void) {
    let center = DistributedNotificationCenter.default()
    let pairs: [(String, Bool)] = [
      ("_NSDoNotDisturbEnabledNotification", true),
      ("_NSDoNotDisturbDisabledNotification", false),
    ]
    for (name, newValue) in pairs {
      let token = center.addObserver(
        forName: Notification.Name(name),
        object: nil,
        queue: .main
      ) { [weak self] _ in
        guard let self else { return }
        cachedActive.withLock { $0 = newValue }
        onChange()
      }
      observers.append(token)
    }
  }
}
