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
      Task { await notch?.compact() }
    } else if isHovering, let notch {
      cancelAutoCollapse()
      Task { await notch.expand() }
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
      Task { await notch?.compact() }
    } else if isHovering, !isPaused, let notch {
      cancelAutoCollapse()
      Task { await notch.expand() }
    }
  }

  /// Sets the auto-collapse timeout. `nil` disables auto-collapse entirely.
  func setAutoCollapseTimeout(_ timeout: Duration?) {
    autoCollapseTimeout = timeout
    if !isHovering {
      scheduleAutoCollapse()
    }
  }

  func expand() {
    guard !isPaused, !isSuppressed, let notch else {
      return
    }
    cancelAutoCollapse()
    Task { await notch.expand() }
  }

  func compact() {
    cancelAutoCollapse()
    Task { await notch?.compact() }
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
    Task { await notch?.compact() }
  }

  private func handleHoverChange(_ hovering: Bool) {
    guard let notch else {
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
      Task {
        await notch.expand()
        notch.windowController?.window?.makeKey()
      }
    } else {
      scheduleAutoCollapse()
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
      await self.notch?.compact()
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
      .font(.system(size: 11, weight: .bold))
      .foregroundStyle(.white.opacity(0.85))
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(Color.clear, in: Capsule())
      .contentShape(Rectangle())
      .help(NotchStrings.suppressionIndicatorHint)
  }

  private var pauseButton: some View {
    HoverButton(action: { viewModel.onResumeRequested?() }) { hovering in
      Image(systemName: hovering ? "play.fill" : "pause.fill")
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(hovering ? Color.accentColor : Color.clear, in: Capsule())
    }
  }
}
