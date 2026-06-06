import Foundation
import Testing

@testable import Gacha

@MainActor
@Test func noticePresenterPreparesFirstQueuedNotice() {
  let fixture = NoticePresenterFixture()
  let first = fixture.queue.enqueue(markdown: "First")
  _ = fixture.queue.enqueue(markdown: "Second")

  #expect(fixture.presenter.prepareForPresentation())
  #expect(fixture.presenter.currentMessage == first)
  #expect(fixture.presenter.canShowNext)
}

@MainActor
@Test func noticePresenterNextRemovesCurrentNoticeAndShowsNext() {
  let fixture = NoticePresenterFixture()
  _ = fixture.queue.enqueue(markdown: "First")
  let second = fixture.queue.enqueue(markdown: "Second")
  _ = fixture.presenter.prepareForPresentation()

  fixture.presenter.actions.onNext()

  #expect(fixture.queue.pending == [second])
  #expect(fixture.presenter.currentMessage == second)
  #expect(!fixture.presenter.canShowNext)
}

@MainActor
@Test func noticePresenterDoesNotRemoveLastNoticeWhenNextIsDisabled() {
  let fixture = NoticePresenterFixture()
  let message = fixture.queue.enqueue(markdown: "Only")
  _ = fixture.presenter.prepareForPresentation()

  fixture.presenter.actions.onNext()

  #expect(fixture.queue.pending == [message])
  #expect(fixture.presenter.currentMessage == message)
  #expect(!fixture.presenter.canShowNext)
}

@MainActor
@Test func noticePresenterConsumeRemovesCurrentNoticeAndClearsPresentation() {
  let fixture = NoticePresenterFixture()
  _ = fixture.queue.enqueue(markdown: "First")
  let second = fixture.queue.enqueue(markdown: "Second")
  _ = fixture.presenter.prepareForPresentation()

  fixture.presenter.consumePresentedNotice()

  #expect(fixture.queue.pending.first == second)
  #expect(fixture.presenter.currentMessage == nil)
}

@MainActor
@Test func noticePresenterConsumeDoesNothingWithoutCurrentPresentation() {
  let fixture = NoticePresenterFixture()

  fixture.presenter.consumePresentedNotice()

  #expect(fixture.queue.pending.isEmpty)
  #expect(fixture.presenter.currentMessage == nil)
}

@MainActor
@Test func noticePresenterPreserveKeepsCurrentNotice() {
  let fixture = NoticePresenterFixture()
  let message = fixture.queue.enqueue(markdown: "Keep")
  _ = fixture.presenter.prepareForPresentation()

  fixture.presenter.preservePresentedNotice()

  #expect(fixture.queue.pending == [message])
  #expect(fixture.presenter.currentMessage == message)
}

@MainActor
@Test func noticePresenterUsesNoticeAutoCollapseSetting() {
  let fixture = NoticePresenterFixture()

  fixture.settingsStore.noticeAutoCollapseSeconds = 8

  #expect(fixture.presenter.presentationPolicy.autoCollapseTimeout == .seconds(8))
}

@MainActor
private struct NoticePresenterFixture {
  let queue = NoticeQueue()
  let settingsStore: SettingsStore
  let presenter: NoticeNotchPresenter

  init() {
    settingsStore = SettingsStore(
      defaults: UserDefaults(suiteName: "NoticeNotchPresenterTests-\(UUID().uuidString)")!)
    presenter = NoticeNotchPresenter(
      noticeQueue: queue,
      cardWindowBridge: CardWindowBridge(windowOpenActionRegistry: WindowOpenActionRegistry()),
      settingsStore: settingsStore)
    presenter.start()
  }
}
