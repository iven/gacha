import Foundation

/// Reports whether the current screen state should suppress the notch. Injected
/// into `SuppressionController` so the gating logic stays testable without
/// touching the live window server.
protocol SuppressionProbing {
  func isSuppressingStateActive() -> Bool

  /// Called once when the controller starts. Probes that have an event-driven
  /// signal (a notification, a callback, etc.) subscribe here and invoke
  /// `onChange` whenever their state may have flipped, giving the controller
  /// zero-latency response. `onChange` must be invoked on the main thread —
  /// the controller dispatches via `MainActor.assumeIsolated` and will trap
  /// otherwise. Pure poll-driven probes leave this as the default no-op and
  /// rely on the controller's poll timer.
  func startReporting(onChange: @escaping @Sendable () -> Void)
}

extension SuppressionProbing {
  func startReporting(onChange: @escaping @Sendable () -> Void) {}
}
