import AppKit

/// Decides whether the notch should be suppressed (kept compact, no hover
/// expand) because another app is in full screen. Re-evaluates on space changes
/// and exposes the result so the notch can gate expansion and show an indicator.
@MainActor
final class SuppressionController: ObservableObject {
  /// Called whenever the suppression result flips.
  var onChange: ((Bool) -> Void)?

  @Published private(set) var isSuppressed = false

  private let probe: SuppressionProbing
  private let isEnabled: () -> Bool
  private var spaceObserver: NSObjectProtocol?

  init(
    probe: SuppressionProbing = FullScreenSpaceDetector(),
    isEnabled: @escaping () -> Bool
  ) {
    self.probe = probe
    self.isEnabled = isEnabled
  }

  func start() {
    spaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
      forName: NSWorkspace.activeSpaceDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.reevaluate()
      }
    }
    reevaluate()
  }

  /// Recomputes the suppression state and notifies on change. Public so the
  /// settings toggle can force a refresh when the user flips the feature.
  func reevaluate() {
    let suppressed = isEnabled() && probe.isSuppressingStateActive()
    guard suppressed != isSuppressed else {
      return
    }

    isSuppressed = suppressed
    onChange?(suppressed)
  }
}
