import Foundation

/// Decides whether the notch should be suppressed (kept compact, no hover
/// expand). Accepts multiple probe/isEnabled pairs; suppression is active when
/// any enabled probe reports true.
///
/// Each probe owns its own event source via `startReporting` for zero-latency
/// response when one exists, and a 1-second poll timer is the backstop for
/// probes without push events. Both paths call the same `reevaluate()`, so
/// there is no double processing — only the state flip matters.
@MainActor
final class SuppressionController {
  struct Source {
    let probe: SuppressionProbing
    // Only called from the main actor; no @Sendable annotation needed.
    let isEnabled: () -> Bool
  }

  /// Called whenever the suppression result flips.
  var onChange: ((Bool) -> Void)?

  private(set) var isSuppressed = false

  private let sources: [Source]
  // Retains the poll timer. The controller is an app-lifetime singleton with
  // no teardown path, so the timer is intentionally never invalidated.
  private var pollTimer: Timer?

  init(sources: [Source]) {
    self.sources = sources
  }

  func start() {
    for source in sources {
      source.probe.startReporting { [weak self] in
        MainActor.assumeIsolated {
          self?.reevaluate()
        }
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
