import Foundation

/// Reports whether the current screen state should suppress the notch. Injected
/// into `SuppressionController` so the gating logic stays testable without
/// touching the live window server.
protocol SuppressionProbing {
  func isSuppressingStateActive() -> Bool
}
