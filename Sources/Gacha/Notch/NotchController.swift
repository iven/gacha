import AppKit
import Combine
import DynamicNotchKit
import SwiftUI

@MainActor
final class NotchController {
  var onHoverChange: ((Bool) -> Void)?
  var onResumeRequested: (() -> Void)?
  var onPausedChange: ((Bool) -> Void)?

  private(set) var isPaused = false
  private(set) var isSuppressed = false
  private(set) var isHovering = false
  private(set) var isExpanded = false
  let autoCollapseSchedule = NotchAutoCollapseSchedule()

  private let viewModel = NotchControllerViewModel()
  private var notch: DynamicNotch<AnyView, AnyView, AnyView>?
  private var hoverObservation: AnyCancellable?
  private var autoCollapseTask: Task<Void, Never>?
  private var globalClickMonitor: Any?
  private var autoCollapseTimeout: Duration?

  init() {}

  func start<Expanded: View, CompactLeading: View>(
    expanded: @escaping () -> Expanded,
    compactLeading: @escaping () -> CompactLeading
  ) {
    viewModel.onResumeRequested = { [weak self] in
      self?.onResumeRequested?()
    }

    let viewModel = self.viewModel
    let notch = DynamicNotch(
      hoverBehavior: .all,
      style: .notch,
      expanded: { AnyView(expanded()) },
      compactLeading: { AnyView(compactLeading()) },
      compactTrailing: { AnyView(NotchCompactTrailingView(viewModel: viewModel)) })
    self.notch = notch
    Task {
      await notch.compact()
      // Exclude the notch panel from screen recordings and sharing. The window
      // is created by DynamicNotchKit during compact(), so set sharingType
      // immediately after it resolves.
      if let window = notch.windowController?.window {
        window.sharingType = .none
      } else {
        AppLogger.app.warning("Notch window unavailable after compact(); sharingType not set")
      }
    }
    hoverObservation =
      notch.$isHovering
      .removeDuplicates()
      .sink { [weak self] hovering in
        self?.handleHoverChange(hovering)
      }
    installGlobalClickMonitor()
  }

  func setPaused(_ paused: Bool) {
    guard isPaused != paused else {
      return
    }

    isPaused = paused
    viewModel.isPaused = paused
    if paused {
      cancelAutoCollapse()
      performCompact()
    } else if isHovering, notch != nil {
      // User just clicked ▶ to resume — they're actively interacting with the
      // notch and likely want to keyboard-rate. Take focus.
      cancelAutoCollapse()
      performExpand(makeKey: true)
    }
    onPausedChange?(paused)
  }

  /// Suppression keeps the notch compact and blocks hover-expand while the user
  /// is presenting. Unlike pause it is system-driven and reverts automatically.
  func setSuppressed(_ suppressed: Bool) {
    guard isSuppressed != suppressed else {
      return
    }

    isSuppressed = suppressed
    viewModel.isSuppressed = suppressed
    if suppressed {
      cancelAutoCollapse()
      performCompact()
    } else if isHovering, !isPaused, notch != nil {
      cancelAutoCollapse()
      performExpand()
    }
  }

  /// Sets the auto-collapse timeout. `nil` disables auto-collapse entirely.
  func setAutoCollapseTimeout(_ timeout: Duration?) {
    autoCollapseTimeout = timeout
    if !isHovering {
      scheduleAutoCollapse()
    }
  }

  /// Expands the notch. `makeKey` should be true only when the user is
  /// actively interacting *with the notch* and expects keyboard input to go
  /// there (hover, global toggle shortcut). Programmatic expand triggered by
  /// other windows (e.g. card management's preview) must keep `makeKey: false`
  /// so it does not steal focus from the originating window.
  func expand(makeKey: Bool = false) {
    guard !isPaused, !isSuppressed, notch != nil else {
      return
    }
    cancelAutoCollapse()
    performExpand(makeKey: makeKey)
  }

  func compact() {
    cancelAutoCollapse()
    performCompact()
  }

  /// Global-shortcut entry point: collapses if currently expanded, otherwise
  /// expands and starts the auto-collapse countdown (so a pointer-less expand
  /// behaves the same as one triggered by a hover that has already left).
  /// No-ops while paused or suppressed, matching hover semantics.
  func toggle() {
    guard !isPaused, !isSuppressed else {
      return
    }
    if isExpanded {
      compact()
    } else {
      expand(makeKey: true)
      scheduleAutoCollapse()
    }
  }

  private func installGlobalClickMonitor() {
    globalClickMonitor = NSEvent.addGlobalMonitorForEvents(
      matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.handleGlobalClick()
      }
    }
  }

  private func handleGlobalClick() {
    guard !isHovering, autoCollapseTask != nil else {
      return
    }

    cancelAutoCollapse()
    performCompact()
  }

  private func handleHoverChange(_ hovering: Bool) {
    guard notch != nil else {
      return
    }

    isHovering = hovering
    onHoverChange?(hovering)

    if isPaused || isSuppressed {
      cancelAutoCollapse()
      return
    }

    if hovering {
      cancelAutoCollapse()
      performExpand(makeKey: true)
    } else {
      scheduleAutoCollapse()
    }
  }

  private func performExpand(makeKey: Bool = false) {
    isExpanded = true
    Task { [notch] in
      await notch?.expand()
      if makeKey {
        notch?.windowController?.window?.makeKey()
      }
    }
  }

  private func performCompact() {
    isExpanded = false
    Task { [notch] in
      await notch?.compact()
    }
  }

  private func scheduleAutoCollapse() {
    cancelAutoCollapse()
    guard let timeout = autoCollapseTimeout else {
      return
    }

    let seconds = timeout.seconds
    if seconds > 0 {
      autoCollapseSchedule.start(duration: seconds)
    } else {
      autoCollapseSchedule.clear()
    }

    autoCollapseTask = Task { [weak self] in
      if timeout > .zero {
        try? await Task.sleep(for: timeout)
      }
      guard let self, !Task.isCancelled else {
        return
      }

      self.autoCollapseSchedule.clear()
      self.performCompact()
    }
  }

  private func cancelAutoCollapse() {
    autoCollapseTask?.cancel()
    autoCollapseTask = nil
    autoCollapseSchedule.clear()
  }
}

@MainActor
final class NotchControllerViewModel: ObservableObject {
  @Published var isPaused = false
  @Published var isSuppressed = false
  var onResumeRequested: (() -> Void)?
}

extension Duration {
  fileprivate var seconds: TimeInterval {
    let (whole, attoseconds) = components
    return TimeInterval(whole) + TimeInterval(attoseconds) / 1.0e18
  }
}

private struct NotchCompactTrailingView: View {
  @ObservedObject var viewModel: NotchControllerViewModel

  var body: some View {
    if viewModel.isSuppressed {
      suppressionIndicator
    } else if viewModel.isPaused {
      pauseButton
    } else {
      pauseButton.hidden()
    }
  }

  // Non-interactive, visually distinct from the user-pause glyph: suppression is
  // system-driven and clears on its own, so there is nothing to tap.
  private var suppressionIndicator: some View {
    Image(systemName: "eye.slash.fill")
      .font(.system(size: NotchToolbarStyle.compactGlyphFontSize, weight: .bold))
      .foregroundStyle(.white.opacity(0.85))
      .notchToolbarControl(restingShell: false)
      .contentShape(Rectangle())
      .help(NotchStrings.suppressionIndicatorHint)
  }

  private var pauseButton: some View {
    HoverButton(action: { viewModel.onResumeRequested?() }) { hovering in
      Image(systemName: hovering ? "play.fill" : "pause.fill")
        .font(.system(size: NotchToolbarStyle.compactGlyphFontSize, weight: .bold))
        .foregroundStyle(.white.opacity(0.85))
        .notchToolbarControl(restingShell: false, highlighted: hovering)
    }
  }
}
