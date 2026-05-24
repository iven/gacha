import AppKit

@MainActor
final class CardDraftSession: NSObject {
  enum FlushResult {
    case noChange
    case saved(MemoryCard)
    case failure
  }

  var onDebouncedFlushNeeded: (() -> Void)?

  private let memoryCardRepository: MemoryCardRepository
  private var draft: Draft?

  init(memoryCardRepository: MemoryCardRepository) {
    self.memoryCardRepository = memoryCardRepository
    super.init()
  }

  func begin(card: MemoryCard?) {
    cancelScheduledFlush()
    draft = card.map { Draft(id: $0.id, body: $0.body) }
  }

  func update(body: String, for cardID: String) {
    draft = Draft(id: cardID, body: body)
  }

  func discard() {
    cancelScheduledFlush()
    draft = nil
  }

  func scheduleFlush() {
    cancelScheduledFlush()
    perform(#selector(fireDebouncedFlush), with: nil, afterDelay: 0.6)
  }

  func cancelScheduledFlush() {
    NSObject.cancelPreviousPerformRequests(
      withTarget: self,
      selector: #selector(fireDebouncedFlush),
      object: nil)
  }

  func flush(against cards: [MemoryCard]) -> FlushResult {
    cancelScheduledFlush()

    guard let draft,
      var card = cards.first(where: { $0.id == draft.id }),
      card.body != draft.body
    else {
      return .noChange
    }

    card.body = draft.body
    card.updatedAt = Date()
    do {
      try memoryCardRepository.write(card)
      self.draft = nil
      return .saved(card)
    } catch {
      AppLogger.app.error("Failed to save memory card: \(error)")
      return .failure
    }
  }

  @objc private func fireDebouncedFlush() {
    onDebouncedFlushNeeded?()
  }
}

private struct Draft {
  let id: String
  var body: String
}
