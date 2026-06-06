import Combine
import Foundation

@MainActor
final class NotchPresentationCoordinator: ObservableObject {
  enum Surface: Equatable {
    case memory
    case notice
  }

  @Published private(set) var surface: Surface = .memory

  let controller: NotchController
  let memoryPresenter: MemoryNotchPresenter
  let noticePresenter: NoticeNotchPresenter
  private let noticeQueue: NoticeQueue
  private var noticeQueueEventCancellable: AnyCancellable?
  private var shouldConsumeNoticeAfterCollapse = false

  init(
    controller: NotchController,
    memoryPresenter: MemoryNotchPresenter,
    noticePresenter: NoticeNotchPresenter,
    noticeQueue: NoticeQueue
  ) {
    self.controller = controller
    self.memoryPresenter = memoryPresenter
    self.noticePresenter = noticePresenter
    self.noticeQueue = noticeQueue

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
    noticePresenter.onCollapseRequested = { [weak controller] in
      controller?.compact()
    }
    noticePresenter.onPauseRequested = { [weak self] in
      self?.setPaused(true)
    }
    noticePresenter.onPresentationStateChanged = { [weak self] in
      self?.handleNoticePresentationStateChanged()
    }

    controller.onWillUserExpand = { [weak self] in
      self?.prepareSurfaceForUserExpand()
    }
    controller.onWillCollapse = { [weak self] disposition in
      self?.handleWillCollapse(disposition: disposition)
    }
    controller.onDidCollapse = { [weak self] in
      self?.handleDidCollapse()
    }
    controller.onResumeRequested = { [weak controller] in
      controller?.setPaused(false)
    }

    controller.setNoticeCount(noticeQueue.pendingCount)
    noticeQueueEventCancellable = noticeQueue.events.sink { [weak self] _ in
      guard let self else { return }
      self.controller.setNoticeCount(self.noticeQueue.pendingCount)
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
    noticePresenter.start()
    syncPresentationState()
  }

  func handleToggleShortcut() {
    switch surface {
    case .memory:
      memoryPresenter.handleToggleShortcut()
    case .notice:
      controller.compact()
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
    case .notice:
      apply(noticePresenter.presentationPolicy)
    }
  }

  private func apply(_ policy: NotchPresentationPolicy) {
    controller.setIdleReminderTimeout(policy.idleReminderTimeout)
    controller.setAutoCollapseTimeout(policy.autoCollapseTimeout)
  }

  private func prepareSurfaceForUserExpand() {
    if noticePresenter.prepareForPresentation() {
      surface = .notice
    } else {
      surface = .memory
    }
    syncPresentationState()
  }

  private func handleWillCollapse(disposition: NotchCollapseDisposition) {
    guard surface == .notice else {
      return
    }

    switch disposition {
    case .finishCurrentPresentation:
      shouldConsumeNoticeAfterCollapse = true
    case .preserveCurrentPresentation:
      shouldConsumeNoticeAfterCollapse = false
      noticePresenter.preservePresentedNotice()
    }
  }

  private func handleDidCollapse() {
    guard shouldConsumeNoticeAfterCollapse else {
      return
    }
    shouldConsumeNoticeAfterCollapse = false
    noticePresenter.consumePresentedNotice()
    if surface == .notice {
      surface = .memory
    }
    syncPresentationState()
  }

  private func handleNoticePresentationStateChanged() {
    if surface == .notice, noticePresenter.currentMessage == nil {
      surface = .memory
    }
    syncPresentationState()
  }
}
