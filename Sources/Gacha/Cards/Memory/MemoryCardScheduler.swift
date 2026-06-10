import FSRS
import Foundation

struct MemoryCardScheduler {
  // PRD §3.3: hardcoded, not user-configurable.
  private static let forgettingExponent: Double = 2
  private static let cooldownTimeConstant: TimeInterval = 60
  private static let forgettingRiskFloor: Double = 1e-6

  private let fsrs: FSRS::FSRS
  private let random: () -> Double

  init(
    parameters: FSRS::FSRSParameters = FSRS::FSRSParameters(w: FSRS::FSRSDefaults.defaultWv6),
    random: @escaping () -> Double = { Double.random(in: 0..<1) }
  ) {
    self.fsrs = FSRS::FSRS(parameters: parameters)
    self.random = random
  }

  func retrievability(for card: MemoryCard, now: Date) -> Double {
    guard card.stability != nil, card.lastSeen != nil else {
      return 0
    }
    return fsrs.getRetrievability(card: makeFSRSCard(from: card), now: now).number
  }

  func isDue(_ card: MemoryCard, now: Date) -> Bool {
    guard let due = card.due else {
      return true
    }
    return now >= due
  }

  func weight(for card: MemoryCard, now: Date) -> Double {
    let forgettingRisk = max(Self.forgettingRiskFloor, 1 - retrievability(for: card, now: now))
    let elapsed = max(0, now.timeIntervalSince(card.lastSeen ?? card.createdAt))
    let cooldown = 1 - exp(-elapsed / Self.cooldownTimeConstant)
    return cooldown * pow(forgettingRisk, Self.forgettingExponent)
  }

  func pickNext(from cards: [MemoryCard], now: Date) -> MemoryCard? {
    guard !cards.isEmpty else {
      return nil
    }
    let dueCards = cards.filter { isDue($0, now: now) }
    if !dueCards.isEmpty {
      return dueCards.min {
        retrievability(for: $0, now: now) < retrievability(for: $1, now: now)
      }
    }
    return weightedRandom(from: cards, now: now)
  }

  func markSeen(_ card: MemoryCard, now: Date) -> MemoryCard {
    var updated = card
    updated.lastSeen = now
    return updated
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

  private func weightedRandom(from cards: [MemoryCard], now: Date) -> MemoryCard? {
    let weights = cards.map { weight(for: $0, now: now) }
    let total = weights.reduce(0, +)
    guard total > 0 else {
      return cards.max {
        ($0.lastSeen ?? $0.createdAt) > ($1.lastSeen ?? $1.createdAt)
      }
    }
    var roll = random() * total
    for (index, value) in weights.enumerated() {
      roll -= value
      if value > 0 && roll <= 0 {
        return cards[index]
      }
    }
    return cards.last
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
