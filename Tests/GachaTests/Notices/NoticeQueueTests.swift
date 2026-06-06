import Foundation
import Testing

@testable import Gacha

@MainActor
@Test func noticeQueueEnqueuesMessagesInFIFOOrder() {
  let baseDate = Date(timeIntervalSince1970: 1_800_000_000)
  let queue = NoticeQueue(
    now: NoticeDateSequence([baseDate, baseDate.addingTimeInterval(1)]).next)

  let first = queue.enqueue(markdown: "First")
  let second = queue.enqueue(markdown: "Second")

  #expect(first.markdown == "First")
  #expect(first.createdAt == baseDate)
  #expect(second.markdown == "Second")
  #expect(queue.pending == [first, second])
  #expect(queue.peek() == first)
}

@MainActor
@Test func noticeQueueRemovesFirstMessage() {
  let queue = NoticeQueue(
    now: { Date(timeIntervalSince1970: 1_800_000_000) })
  let first = queue.enqueue(markdown: "First")
  let second = queue.enqueue(markdown: "Second")

  let removed = queue.removeFirst()

  #expect(removed == first)
  #expect(queue.pending == [second])
  #expect(queue.peek() == second)
}

@MainActor
@Test func noticeQueueClearRemovesAllMessages() {
  let queue = NoticeQueue(
    now: { Date(timeIntervalSince1970: 1_800_000_000) })
  _ = queue.enqueue(markdown: "First")
  _ = queue.enqueue(markdown: "Second")

  queue.clear()

  #expect(queue.pending.isEmpty)
  #expect(queue.isEmpty)
}

@MainActor
@Test func noticeQueuePublishesLifecycleEvents() {
  let queue = NoticeQueue(
    now: { Date(timeIntervalSince1970: 1_800_000_000) })
  var observed: [NoticeQueueEvent] = []
  let cancellable = queue.events.sink { observed.append($0) }

  let first = queue.enqueue(markdown: "First")
  let second = queue.enqueue(markdown: "Second")
  _ = queue.removeFirst()
  queue.clear()

  #expect(
    observed == [
      .didEnqueue(first),
      .didEnqueue(second),
      .didRemove(first),
      .didClear([second]),
    ])
  cancellable.cancel()
}

@MainActor
@Test func noticeQueueDoesNotPublishEventsForNoOpRemovals() {
  let queue = NoticeQueue()
  var observed: [NoticeQueueEvent] = []
  let cancellable = queue.events.sink { observed.append($0) }

  #expect(queue.removeFirst() == nil)
  queue.clear()

  #expect(observed.isEmpty)
  cancellable.cancel()
}

private final class NoticeDateSequence {
  private var dates: ArraySlice<Date>

  init(_ dates: [Date]) {
    self.dates = ArraySlice(dates)
  }

  func next() -> Date {
    dates.removeFirst()
  }
}
