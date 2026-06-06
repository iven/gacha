import AppKit
import Combine
import DynamicNotchKit
import SwiftUI

@MainActor
final class NotchController {
  var onHoverChange: ((Bool) -> Void)?
  var onResumeRequested: (() -> Void)?
  var onPausedChange: ((Bool) -> Void)?

  private(set) var isPaused = false {
    didSet {
      viewModel.isPaused = isPaused
      syncSuppression()
    }
  }
  private(set) var isSystemSuppressed = false {
    didSet {
      viewModel.isSuppressed = isSystemSuppressed
      syncSuppression()
    }
  }
  private var isSuppressed: Bool {
    isPaused || isSystemSuppressed
  }
  private(set) var isHovering = false
  private(set) var isExpanded = false
  let autoCollapseSchedule = NotchAutoCollapseSchedule()
  let idleReminderState = NotchIdleReminderState()

  private let viewModel = NotchControllerViewModel()
  private var notch: DynamicNotch<AnyView, AnyView, AnyView>?
  private var hoverObservation: AnyCancellable?
  private var autoCollapseTask: Task<Void, Never>?
  private var idleReminderTask: Task<Void, Never>?
  private var globalClickMonitor: Any?
  private var autoCollapseTimeout: Duration?
  private var idleReminderTimeout: Duration?

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
      // DynamicNotchKit starts hidden; compact() creates and shows the compact panel.
      await notch.compact()
      idleReminderState.trigger(pulseCount: 1)
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
    if paused {
      collapse()
    } else if isHovering, !isSuppressed, notch != nil {
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
    guard isSystemSuppressed != suppressed else {
      return
    }

    isSystemSuppressed = suppressed
    if suppressed {
      collapse()
    } else if isHovering, !isSuppressed, notch != nil {
      cancelAutoCollapse()
      performExpand()
    }
  }

  func setNoticeCount(_ count: Int) {
    viewModel.noticeCount = count
  }

  /// Sets the auto-collapse timeout. `nil` disables auto-collapse entirely.
  func setAutoCollapseTimeout(_ timeout: Duration?) {
    autoCollapseTimeout = timeout
    if !isHovering {
      scheduleAutoCollapse()
    }
  }

  func setIdleReminderTimeout(_ timeout: Duration?) {
    idleReminderTimeout = timeout
    restartIdleReminder()
  }

  /// Expands the notch. `makeKey` should be true only when the user is
  /// actively interacting *with the notch* and expects keyboard input to go
  /// there (hover, global toggle shortcut). Programmatic expand triggered by
  /// other windows (e.g. card management's preview) must keep `makeKey: false`
  /// so it does not steal focus from the originating window.
  func expand(makeKey: Bool = false) {
    guard !isSuppressed, notch != nil else {
      return
    }
    cancelAutoCollapse()
    performExpand(makeKey: makeKey)
  }

  func compact() {
    collapse()
  }

  /// Global-shortcut entry point: collapses if currently expanded, otherwise
  /// expands and starts the auto-collapse countdown (so a pointer-less expand
  /// behaves the same as one triggered by a hover that has already left).
  /// No-ops while suppressed, matching hover semantics.
  func toggle() {
    guard !isSuppressed else {
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

    collapse()
  }

  private func handleHoverChange(_ hovering: Bool) {
    guard notch != nil else {
      return
    }

    isHovering = hovering
    onHoverChange?(hovering)

    if isSuppressed {
      cancelAutoCollapse()
      return
    }

    if hovering {
      cancelAutoCollapse()
      performExpand(makeKey: true)
    } else {
      scheduleAutoCollapse()
      restartIdleReminder()
    }
  }

  private func performExpand(makeKey: Bool = false) {
    isExpanded = true
    cancelIdleReminder()
    Task { [notch] in
      await notch?.expand()
      if makeKey {
        notch?.windowController?.window?.makeKey()
      }
    }
  }

  private func performCompact() {
    isExpanded = false
    restartIdleReminder()
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

      self.collapse()
    }
  }

  private func collapse() {
    cancelAutoCollapse()
    performCompact()
  }

  private func cancelAutoCollapse() {
    autoCollapseTask?.cancel()
    autoCollapseTask = nil
    autoCollapseSchedule.clear()
  }

  private func restartIdleReminder() {
    cancelIdleReminder()
    startIdleReminder()
  }

  // Both setters guard against no-op writes, so a didSet only fires on a real
  // change. Reaching a non-suppressed state therefore means suppression just
  // lifted — the moment to resume the idle reminder cadence.
  private func syncSuppression() {
    idleReminderState.isSuppressed = isSuppressed
    if !isSuppressed {
      restartIdleReminder()
    }
  }

  // Runs a repeating cadence while the notch is compact and not suppressed.
  // Suppression pauses the cadence; syncSuppression restarts it once lifted.
  private func startIdleReminder() {
    guard
      let timeout = idleReminderTimeout,
      timeout > .zero,
      !isExpanded,
      !isSuppressed
    else {
      return
    }

    idleReminderTask = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: timeout)
        guard let self, !Task.isCancelled else {
          return
        }

        self.idleReminderState.trigger(pulseCount: 5)
      }
    }
  }

  private func cancelIdleReminder() {
    idleReminderTask?.cancel()
    idleReminderTask = nil
  }
}

@MainActor
final class NotchControllerViewModel: ObservableObject {
  @Published var isPaused = false
  @Published var isSuppressed = false
  @Published var noticeCount = 0
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
    ZStack {
      if viewModel.isSuppressed {
        suppressionIndicator
          .transition(indicatorTransition)
      } else if viewModel.isPaused {
        pauseButton
          .transition(indicatorTransition)
      } else if viewModel.noticeCount > 0 {
        NoticeCountIndicator(count: viewModel.noticeCount)
          .transition(indicatorTransition)
      } else {
        pauseButton.hidden()
          .transition(.opacity)
      }
    }
    .animation(.easeInOut(duration: 0.22), value: viewModel.isSuppressed)
    .animation(.easeInOut(duration: 0.22), value: viewModel.isPaused)
    .animation(.easeInOut(duration: 0.22), value: viewModel.noticeCount > 0)
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

  private var indicatorTransition: AnyTransition {
    .opacity.combined(with: .scale(scale: 0.86))
  }
}

private struct NoticeCountIndicator: View {
  let count: Int

  var body: some View {
    NotchAnimatedCue(
      triggerID: count,
      pulseCount: 5,
      restingShell: false,
      showsShellWhileAnimating: true
    ) { pulseAmount in
      Text(formattedCount)
        .font(.custom("Avenir-Black", size: NotchToolbarStyle.compactGlyphFontSize))
        .foregroundStyle(.white.opacity(0.85 + pulseAmount * 0.15))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .contentTransition(.numericText(value: Double(count)))
    }
  }

  private var formattedCount: String {
    count > 99 ? "99+" : "\(count)"
  }
}
