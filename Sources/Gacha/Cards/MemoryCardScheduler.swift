import FSRS
import Foundation

struct MemoryCardScheduler {
  // PRD §3.3: hardcoded, not user-configurable.
  private static let lastSeenPenaltyDecay: Double = 1.0
  private static let lastSeenPenaltyTimeConstant: TimeInterval = 60 * 60
  static let secondsPerDay: Double = 86_400
  private static let stabilityFloor: Double = 0.001

  private let fsrs: FSRS::FSRS

  init(parameters: FSRS::FSRSParameters = FSRS::FSRSParameters()) {
    self.fsrs = FSRS::FSRS(parameters: parameters)
  }

  func urgency(for card: MemoryCard, now: Date) -> Double {
    let due = card.due ?? card.createdAt
    let stability = max(card.stability ?? 0, Self.stabilityFloor)
    let elapsedDays = now.timeIntervalSince(due) / Self.secondsPerDay
    let retrievabilityTerm = elapsedDays / stability

    let penalty: Double
    if let lastSeen = card.lastSeen {
      let elapsedSeconds = now.timeIntervalSince(lastSeen)
      penalty = -Self.lastSeenPenaltyDecay * exp(-elapsedSeconds / Self.lastSeenPenaltyTimeConstant)
    } else {
      penalty = 0
    }

    return retrievabilityTerm + penalty
  }

  func pickNext(from cards: [MemoryCard], now: Date) -> MemoryCard? {
    cards.max { lhs, rhs in
      urgency(for: lhs, now: now) < urgency(for: rhs, now: now)
    }
  }

  func apply(rating: MemoryCardRating, to card: MemoryCard, now: Date) throws -> MemoryCard {
    var updated = card
    updated.lastSeen = now

    if let due = card.due, now < due {
      return updated
    }

    let fsrsCard = makeFSRSCard(from: card)
    let result = try fsrs.next(card: fsrsCard, now: now, grade: rating)
    updated.stability = result.card.stability
    updated.difficulty = result.card.difficulty
    updated.due = result.card.due
    return updated
  }

  private func makeFSRSCard(from card: MemoryCard) -> FSRS::Card {
    let isNew = card.stability == nil && card.difficulty == nil && card.lastSeen == nil
    return FSRS::Card(
      due: card.due ?? card.createdAt,
      stability: card.stability ?? 0,
      difficulty: card.difficulty ?? 0,
      state: isNew ? FSRS::CardState.new : FSRS::CardState.review,
      lastReview: card.lastSeen
    )
  }
}
