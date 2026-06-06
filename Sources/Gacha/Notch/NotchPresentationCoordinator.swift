import Foundation

@MainActor
final class NotchPresentationCoordinator: ObservableObject {
  enum Surface: Equatable {
    case memory
  }

  @Published private(set) var surface: Surface = .memory

  let controller: NotchController
  let memoryPresenter: MemoryNotchPresenter

  init(controller: NotchController, memoryPresenter: MemoryNotchPresenter) {
    self.controller = controller
    self.memoryPresenter = memoryPresenter

    memoryPresenter.onCollapseRequested = { [weak controller] in
      controller?.compact()
    }
    memoryPresenter.onToggleRequested = { [weak controller] in
      controller?.toggle()
    }
    memoryPresenter.onExpandRequested = { [weak controller] in
      controller?.expand()
    }
    memoryPresenter.onPauseRequested = { [weak self] in
      self?.setPaused(true)
    }
    memoryPresenter.onPresentationStateChanged = { [weak self] in
      self?.syncPresentationState()
    }

    controller.onResumeRequested = { [weak controller] in
      controller?.setPaused(false)
    }
  }

  func start() {
    let schedule = controller.autoCollapseSchedule
    let idleReminderState = controller.idleReminderState
    controller.start(
      expanded: {
        NotchExpandedView(coordinator: self, autoCollapseSchedule: schedule)
      },
      compactLeading: {
        LogoCompactView(idleReminderState: idleReminderState)
      })
    memoryPresenter.start()
    syncPresentationState()
  }

  func handleToggleShortcut() {
    switch surface {
    case .memory:
      memoryPresenter.handleToggleShortcut()
    }
  }

  func setPaused(_ paused: Bool) {
    controller.setPaused(paused)
  }

  func setSuppressed(_ suppressed: Bool) {
    controller.setSuppressed(suppressed)
  }

  func refreshIdleReminderTimeout() {
    syncPresentationState()
  }

  private func syncPresentationState() {
    switch surface {
    case .memory:
      apply(memoryPresenter.presentationPolicy)
    }
  }

  private func apply(_ policy: NotchPresentationPolicy) {
    controller.setIdleReminderTimeout(policy.idleReminderTimeout)
    controller.setAutoCollapseTimeout(policy.autoCollapseTimeout)
  }
}
