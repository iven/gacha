import Foundation
import Testing

@testable import Gacha

@MainActor
@Test func coordinatorPresentsQueuedNoticeOnUserExpand() throws {
  let fixture = try CoordinatorFixture()
  let message = fixture.queue.enqueue(markdown: "Hello")

  fixture.controller.onWillUserExpand?()

  #expect(fixture.coordinator.surface == .notice)
  #expect(fixture.noticePresenter.currentMessage == message)
}

@MainActor
@Test func coordinatorExpandsToMemoryWhenNoticeQueueEmpty() throws {
  let fixture = try CoordinatorFixture()

  fixture.controller.onWillUserExpand?()

  #expect(fixture.coordinator.surface == .memory)
  #expect(fixture.noticePresenter.currentMessage == nil)
}

@MainActor
@Test func coordinatorFinishingCollapseConsumesNoticeAndReturnsToMemory() throws {
  let fixture = try CoordinatorFixture()
  _ = fixture.queue.enqueue(markdown: "First")
  let second = fixture.queue.enqueue(markdown: "Second")

  fixture.controller.onWillUserExpand?()
  fixture.controller.onWillCollapse?(.finishCurrentPresentation)
  fixture.controller.onDidCollapse?()

  #expect(fixture.queue.pending == [second])
  #expect(fixture.coordinator.surface == .memory)
  #expect(fixture.noticePresenter.currentMessage == nil)
}

@MainActor
@Test func coordinatorPreservingCollapseKeepsNoticeAndSurface() throws {
  let fixture = try CoordinatorFixture()
  let kept = fixture.queue.enqueue(markdown: "Keep")

  fixture.controller.onWillUserExpand?()
  fixture.controller.onWillCollapse?(.preserveCurrentPresentation)
  fixture.controller.onDidCollapse?()

  #expect(fixture.queue.pending == [kept])
  #expect(fixture.coordinator.surface == .notice)
  #expect(fixture.noticePresenter.currentMessage == kept)
}

@MainActor
private final class CoordinatorFixture {
  let controller = NotchController()
  let queue = NoticeQueue()
  let memoryPresenter: MemoryNotchPresenter
  let noticePresenter: NoticeNotchPresenter
  let coordinator: NotchPresentationCoordinator
  private let rootURL: URL

  init() throws {
    rootURL = URL(fileURLWithPath: "/tmp/agents/GachaTests/\(UUID().uuidString)")
    let directories = AppDirectories(
      applicationSupportURL: rootURL.appendingPathComponent("Application Support"),
      userStorageURL: rootURL.appendingPathComponent("Documents"))
    let repository = try MemoryCardRepository(directories: directories)
    let settingsStore = SettingsStore(
      defaults: UserDefaults(suiteName: "NotchPresentationCoordinatorTests-\(UUID().uuidString)")!)
    let cardWindowBridge = CardWindowBridge(
      windowOpenActionRegistry: WindowOpenActionRegistry())
    memoryPresenter = MemoryNotchPresenter(
      memoryCardRepository: repository,
      settingsStore: settingsStore,
      cardWindowBridge: cardWindowBridge)
    noticePresenter = NoticeNotchPresenter(
      noticeQueue: queue,
      cardWindowBridge: cardWindowBridge,
      settingsStore: settingsStore)
    coordinator = NotchPresentationCoordinator(
      controller: controller,
      memoryPresenter: memoryPresenter,
      noticePresenter: noticePresenter,
      noticeQueue: queue)
    noticePresenter.start()
  }

  deinit {
    try? FileManager.default.removeItem(at: rootURL)
  }
}
