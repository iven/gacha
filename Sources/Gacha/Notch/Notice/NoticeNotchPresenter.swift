import Combine
import Foundation

@MainActor
final class NoticeNotchPresenter: ObservableObject {
  @Published private(set) var currentMessage: NoticeMessage?
  @Published private(set) var isSettingsVisible = false

  var onPauseRequested: (() -> Void)?
  var onSettingsRequested: (() -> Void)?
  var onCollapseRequested: (() -> Void)?
  var onPresentationStateChanged: (() -> Void)?

  private let noticeQueue: NoticeQueue
  private let cardWindowBridge: CardWindowBridge
  private let settingsStore: SettingsStore
  private var observations: Set<AnyCancellable> = []
  private var isApplyingQueueMutation = false

  init(
    noticeQueue: NoticeQueue,
    cardWindowBridge: CardWindowBridge,
    settingsStore: SettingsStore
  ) {
    self.noticeQueue = noticeQueue
    self.cardWindowBridge = cardWindowBridge
    self.settingsStore = settingsStore
  }

  var actions: NoticeNotchActions {
    NoticeNotchActions(
      onNext: { [weak self] in self?.showNext() },
      onOpenSettings: { [weak self] in self?.onSettingsRequested?() },
      onPause: { [weak self] in self?.onPauseRequested?() },
      onDismiss: { [weak self] in self?.onCollapseRequested?() })
  }

  var canShowNext: Bool {
    noticeQueue.pendingCount > 1
  }

  var presentationPolicy: NotchPresentationPolicy {
    NotchPresentationPolicy(
      autoCollapseTimeout: .seconds(settingsStore.noticeAutoCollapseSeconds),
      idleReminderTimeout: nil)
  }

  func start() {
    cardWindowBridge.$settingsVisible
      .removeDuplicates()
      .assign(to: &$isSettingsVisible)

    noticeQueue.events
      .sink { [weak self] _ in
        self?.handleQueueChanged()
      }
      .store(in: &observations)
  }

  func prepareForPresentation() -> Bool {
    guard let message = noticeQueue.peek() else {
      setCurrentMessage(nil)
      return false
    }
    setCurrentMessage(message)
    return true
  }

  func consumePresentedNotice() {
    guard currentMessage != nil else {
      return
    }
    removeFirstQueuedNotice()
    setCurrentMessage(nil)
  }

  func preservePresentedNotice() {
    setCurrentMessage(noticeQueue.peek())
  }

  private func showNext() {
    guard canShowNext else {
      return
    }
    removeFirstQueuedNotice()
    setCurrentMessage(noticeQueue.peek())
  }

  private func handleQueueChanged() {
    guard !isApplyingQueueMutation else {
      return
    }
    guard currentMessage != nil else {
      return
    }
    setCurrentMessage(noticeQueue.peek())
  }

  private func removeFirstQueuedNotice() {
    isApplyingQueueMutation = true
    defer { isApplyingQueueMutation = false }
    _ = noticeQueue.removeFirst()
  }

  private func setCurrentMessage(_ message: NoticeMessage?) {
    guard currentMessage != message else {
      return
    }
    currentMessage = message
    onPresentationStateChanged?()
  }
}
