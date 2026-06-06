import Combine
import Foundation

@MainActor
final class NoticeQueue {
  private let now: () -> Date
  private var messages: [NoticeMessage] = []
  private let eventSubject = PassthroughSubject<NoticeQueueEvent, Never>()

  var events: AnyPublisher<NoticeQueueEvent, Never> {
    eventSubject.eraseToAnyPublisher()
  }

  var pending: [NoticeMessage] {
    messages
  }

  var isEmpty: Bool {
    messages.isEmpty
  }

  init(
    now: @escaping () -> Date = Date.init
  ) {
    self.now = now
  }

  @discardableResult
  func enqueue(markdown: String) -> NoticeMessage {
    let message = NoticeMessage(
      markdown: markdown,
      createdAt: now())
    messages.append(message)
    eventSubject.send(.didEnqueue(message))
    return message
  }

  func peek() -> NoticeMessage? {
    messages.first
  }

  @discardableResult
  func removeFirst() -> NoticeMessage? {
    guard let message = messages.first else {
      return nil
    }

    messages.removeFirst()
    eventSubject.send(.didRemove(message))
    return message
  }

  func clear() {
    guard !messages.isEmpty else {
      return
    }

    let removed = messages
    messages.removeAll()
    eventSubject.send(.didClear(removed))
  }
}
