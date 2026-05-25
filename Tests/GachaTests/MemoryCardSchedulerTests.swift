import Foundation
import Testing

@testable import Gacha

private let secondsPerDay: TimeInterval = 86_400

@Test func retrievabilityIsZeroForUnreviewedCard() {
  let scheduler = MemoryCardScheduler()
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let card = makeCard(createdAt: now, due: now)

  #expect(scheduler.retrievability(for: card, now: now) == 0)
}

@Test func retrievabilityDecaysFromOneAfterReview() {
  let scheduler = MemoryCardScheduler()
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let stability = 4.0
  let card = makeCard(
    createdAt: now,
    due: now.addingTimeInterval(secondsPerDay * stability),
    stability: stability,
    lastSeen: now
  )
  let later = now.addingTimeInterval(secondsPerDay * stability)

  #expect(abs(scheduler.retrievability(for: card, now: now) - 1.0) < 1e-9)
  #expect(abs(scheduler.retrievability(for: card, now: later) - 0.9) < 1e-9)
}

@Test func pickNextPrefersDueCardWithLowerRetrievability() {
  let scheduler = MemoryCardScheduler()
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let dueLongAgo = now.addingTimeInterval(-secondsPerDay * 5)
  let dueRecently = now.addingTimeInterval(-secondsPerDay)
  let urgent = makeCard(
    id: "a",
    createdAt: dueLongAgo,
    due: dueLongAgo,
    stability: 1.0,
    lastSeen: dueLongAgo
  )
  let lessUrgent = makeCard(
    id: "b",
    createdAt: dueRecently,
    due: dueRecently,
    stability: 1.0,
    lastSeen: dueRecently
  )

  let next = scheduler.pickNext(from: [lessUrgent, urgent], now: now)

  #expect(next == urgent)
}

@Test func pickNextPrefersDueCardOverNonDue() {
  let scheduler = MemoryCardScheduler()
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let due = now.addingTimeInterval(-secondsPerDay)
  let dueCard = makeCard(id: "a", createdAt: due, due: due, stability: 1.0, lastSeen: due)
  let futureCard = makeCard(
    id: "b",
    createdAt: now.addingTimeInterval(-secondsPerDay * 2),
    due: now.addingTimeInterval(secondsPerDay),
    stability: 5.0,
    lastSeen: now.addingTimeInterval(-secondsPerDay)
  )

  let next = scheduler.pickNext(from: [futureCard, dueCard], now: now)

  #expect(next == dueCard)
}

@Test func pickNextTreatsCardWithoutDueAsDue() {
  let scheduler = MemoryCardScheduler()
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let newCard = makeCard(id: "a", createdAt: now, due: nil)

  let next = scheduler.pickNext(from: [newCard], now: now)

  #expect(next == newCard)
}

@Test func pickNextReturnsNilForEmptyCardPool() {
  let scheduler = MemoryCardScheduler()
  let now = Date(timeIntervalSince1970: 1_800_000_000)

  #expect(scheduler.pickNext(from: [], now: now) == nil)
}

@Test func weightFavorsHigherForgettingRiskAmongNonDueCards() {
  let scheduler = MemoryCardScheduler()
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let elapsed = secondsPerDay
  let weak = makeCard(
    id: "a",
    createdAt: now.addingTimeInterval(-elapsed),
    due: now.addingTimeInterval(secondsPerDay),
    stability: 1.0,
    lastSeen: now.addingTimeInterval(-elapsed)
  )
  let strong = makeCard(
    id: "b",
    createdAt: now.addingTimeInterval(-elapsed),
    due: now.addingTimeInterval(secondsPerDay * 100),
    stability: 100.0,
    lastSeen: now.addingTimeInterval(-elapsed)
  )

  let weakWeight = scheduler.weight(for: weak, now: now)
  let strongWeight = scheduler.weight(for: strong, now: now)

  #expect(weakWeight > strongWeight)
}

@Test func weightFavorsCardNotSeenForLonger() {
  let scheduler = MemoryCardScheduler()
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let stale = makeCard(
    id: "a",
    createdAt: now.addingTimeInterval(-secondsPerDay * 2),
    due: now.addingTimeInterval(secondsPerDay),
    stability: 1.0,
    lastSeen: now.addingTimeInterval(-secondsPerDay * 2)
  )
  let fresh = makeCard(
    id: "b",
    createdAt: now.addingTimeInterval(-secondsPerDay * 2),
    due: now.addingTimeInterval(secondsPerDay),
    stability: 1.0,
    lastSeen: now.addingTimeInterval(-secondsPerDay)
  )

  #expect(scheduler.weight(for: stale, now: now) > scheduler.weight(for: fresh, now: now))
}

@Test func weightedRandomSkipsJustSeenCard() {
  let scheduler = MemoryCardScheduler(random: { 0.5 })
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let justSeen = makeCard(
    id: "a",
    createdAt: now.addingTimeInterval(-secondsPerDay),
    due: now.addingTimeInterval(secondsPerDay),
    stability: 1.0,
    lastSeen: now
  )
  let other = makeCard(
    id: "b",
    createdAt: now.addingTimeInterval(-secondsPerDay),
    due: now.addingTimeInterval(secondsPerDay),
    stability: 1.0,
    lastSeen: now.addingTimeInterval(-secondsPerDay)
  )

  let next = scheduler.pickNext(from: [justSeen, other], now: now)

  #expect(next == other)
}

@Test func pickNextAvoidsJustSeenCardEvenWhenAllRetrievabilityIsOne() {
  let scheduler = MemoryCardScheduler(random: { 0.0 })
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let justSeen = makeCard(
    id: "a",
    createdAt: now.addingTimeInterval(-secondsPerDay),
    due: now.addingTimeInterval(secondsPerDay * 4),
    stability: 4.0,
    lastSeen: now
  )
  let alsoFresh = makeCard(
    id: "b",
    createdAt: now.addingTimeInterval(-secondsPerDay),
    due: now.addingTimeInterval(secondsPerDay * 4),
    stability: 4.0,
    lastSeen: now.addingTimeInterval(-30)
  )

  let next = scheduler.pickNext(from: [justSeen, alsoFresh], now: now)

  #expect(next == alsoFresh)
}

@Test func applyRatingOnDueCardUpdatesFSRSStateAndLastSeen() throws {
  let scheduler = MemoryCardScheduler()
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let due = now.addingTimeInterval(-secondsPerDay)
  let card = makeCard(createdAt: due, due: due)

  let updated = try scheduler.apply(rating: .good, to: card, now: now)

  #expect(updated.lastSeen == now)
  #expect(updated.stability != nil)
  #expect(updated.stability != card.stability)
  #expect(updated.difficulty != nil)
  #expect(updated.due != nil)
  #expect(updated.due! > now)
}

@Test func applyRatingBeforeDueOnlyUpdatesLastSeen() throws {
  let scheduler = MemoryCardScheduler()
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let due = now.addingTimeInterval(secondsPerDay)
  let card = makeCard(
    createdAt: now.addingTimeInterval(-secondsPerDay),
    due: due,
    stability: 4.2,
    difficulty: 0.31,
    lastSeen: now.addingTimeInterval(-secondsPerDay)
  )

  let updated = try scheduler.apply(rating: .good, to: card, now: now)

  #expect(updated.lastSeen == now)
  #expect(updated.due == card.due)
  #expect(updated.stability == card.stability)
  #expect(updated.difficulty == card.difficulty)
}

@Test func applyRatingAgainOnDueCardIsAccepted() throws {
  let scheduler = MemoryCardScheduler()
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let due = now.addingTimeInterval(-secondsPerDay)
  let card = makeCard(createdAt: due, due: due)

  let updated = try scheduler.apply(rating: .again, to: card, now: now)

  #expect(updated.lastSeen == now)
  #expect(updated.stability != nil)
}

private func makeCard(
  id: String = "20260524-000000-aaaaaa",
  createdAt: Date,
  due: Date?,
  stability: Double? = nil,
  difficulty: Double? = nil,
  lastSeen: Date? = nil
) -> MemoryCard {
  MemoryCard(
    id: id,
    body: "title\n\nbody",
    directory: "Uncategorized",
    due: due,
    stability: stability,
    difficulty: difficulty,
    lastSeen: lastSeen,
    createdAt: createdAt,
    updatedAt: createdAt
  )
}
