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
    Task { await notch.compact() }
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

  /// Sets the auto-collapse timeout. `nil` disables auto-collapse entirely.
  func setAutoCollapseTimeout(_ timeout: Duration?) {
    autoCollapseTimeout = timeout
    if !isHovering {
      scheduleAutoCollapse()
    }
  }

  func expand() {
    guard !isPaused, let notch else {
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

    if isPaused {
      cancelAutoCollapse()
      return
    }

    if hovering {
      cancelAutoCollapse()
      Task { await notch.expand() }
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
  @State private var isHovering = false

  var body: some View {
    if viewModel.isPaused {
      pauseButton
    } else {
      pauseButton.hidden()
    }
  }

  private var pauseButton: some View {
    Button {
      viewModel.onResumeRequested?()
    } label: {
      Image(systemName: isHovering ? "play.fill" : "pause.fill")
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isHovering ? Color.blue : Color.clear, in: Capsule())
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      isHovering = hovering
      if hovering {
        NSCursor.pointingHand.push()
      } else {
        NSCursor.pop()
      }
    }
  }
}
