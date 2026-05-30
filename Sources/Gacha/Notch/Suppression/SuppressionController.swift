import AppKit

/// Decides whether the notch should be suppressed (kept compact, no hover
/// expand). Accepts multiple probe/isEnabled pairs; suppression is active when
/// any enabled probe reports true.
///
/// Two re-evaluation mechanisms run in parallel:
/// - `activeSpaceDidChange` notification: fires immediately on Space switches,
///   giving zero-latency response for full-screen transitions triggered that way.
/// - 1-second poll timer: backstop for probes that have no notification (e.g.
///   `ScreenCaptureDetector`) and for full-screen toggles that don't switch
///   Spaces. Both mechanisms call the same `reevaluate()`, so there is no double
///   processing — only the state flip matters.
@MainActor
final class SuppressionController: ObservableObject {
  struct Source {
    let probe: SuppressionProbing
    // Only called from the main actor; no @Sendable annotation needed.
    let isEnabled: () -> Bool
  }

  /// Called whenever the suppression result flips.
  var onChange: ((Bool) -> Void)?

  @Published private(set) var isSuppressed = false

  private let sources: [Source]
  // Retains the space-change observer token for the controller's lifetime.
  private var spaceObserver: NSObjectProtocol?
  // Retains the poll timer. The controller is an app-lifetime singleton with
  // no teardown path, so the timer is intentionally never invalidated.
  private var pollTimer: Timer?

  init(sources: [Source]) {
    self.sources = sources
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

    let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
      [weak self] _ in
      MainActor.assumeIsolated {
        self?.reevaluate()
      }
    }
    timer.tolerance = 0.2
    pollTimer = timer

    reevaluate()
  }

  /// Recomputes the suppression state and notifies on change. Public so the
  /// settings toggles can force a refresh when the user flips a feature.
  func reevaluate() {
    let suppressed = sources.contains { $0.isEnabled() && $0.probe.isSuppressingStateActive() }
    guard suppressed != isSuppressed else {
      return
    }

    isSuppressed = suppressed
    onChange?(suppressed)
  }
}
