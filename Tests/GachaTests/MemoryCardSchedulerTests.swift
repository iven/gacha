import Foundation
import Testing

@testable import Gacha

@Test func urgencyForNewCardIsZeroAtCreation() {
  let scheduler = MemoryCardScheduler()
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let card = makeCard(createdAt: now, due: now)

  #expect(scheduler.urgency(for: card, now: now) == 0)
}

@Test func urgencyGrowsAfterDueWithLowerStability() {
  let scheduler = MemoryCardScheduler()
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let due = now.addingTimeInterval(-MemoryCardScheduler.secondsPerDay)
  let lowStability = makeCard(createdAt: due, due: due, stability: 1.0)
  let highStability = makeCard(createdAt: due, due: due, stability: 5.0)

  let lowUrgency = scheduler.urgency(for: lowStability, now: now)
  let highUrgency = scheduler.urgency(for: highStability, now: now)

  #expect(lowUrgency > highUrgency)
  #expect(abs(lowUrgency - 1.0) < 1e-9)
  #expect(abs(highUrgency - 0.2) < 1e-9)
}

@Test func urgencyAppliesLastSeenPenaltyThatDecaysOverTime() {
  let scheduler = MemoryCardScheduler()
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let due = now.addingTimeInterval(-MemoryCardScheduler.secondsPerDay)
  let neverSeen = makeCard(createdAt: due, due: due, stability: 1.0, lastSeen: nil)
  let justSeen = makeCard(createdAt: due, due: due, stability: 1.0, lastSeen: now)
  let seenLongAgo = makeCard(
    createdAt: due,
    due: due,
    stability: 1.0,
    lastSeen: now.addingTimeInterval(-60 * 60 * 10)
  )

  let neverSeenUrgency = scheduler.urgency(for: neverSeen, now: now)
  let justSeenUrgency = scheduler.urgency(for: justSeen, now: now)
  let seenLongAgoUrgency = scheduler.urgency(for: seenLongAgo, now: now)

  #expect(justSeenUrgency < neverSeenUrgency)
  #expect(seenLongAgoUrgency > justSeenUrgency)
  #expect(abs(seenLongAgoUrgency - neverSeenUrgency) < 1e-3)
  #expect(abs(justSeenUrgency - (1.0 - 1.0)) < 1e-9)
}

@Test func pickNextChoosesHighestUrgency() {
  let scheduler = MemoryCardScheduler()
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let dueLongAgo = now.addingTimeInterval(-MemoryCardScheduler.secondsPerDay * 3)
  let dueRecently = now.addingTimeInterval(-MemoryCardScheduler.secondsPerDay)
  let urgent = makeCard(id: "a", createdAt: dueLongAgo, due: dueLongAgo, stability: 1.0)
  let lessUrgent = makeCard(id: "b", createdAt: dueRecently, due: dueRecently, stability: 1.0)

  let next = scheduler.pickNext(from: [lessUrgent, urgent], now: now)

  #expect(next == urgent)
}

@Test func pickNextReturnsNilForEmptyCardPool() {
  let scheduler = MemoryCardScheduler()
  let now = Date(timeIntervalSince1970: 1_800_000_000)

  #expect(scheduler.pickNext(from: [], now: now) == nil)
}

@Test func applyRatingOnDueCardUpdatesFSRSStateAndLastSeen() throws {
  let scheduler = MemoryCardScheduler()
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let due = now.addingTimeInterval(-MemoryCardScheduler.secondsPerDay)
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
  let due = now.addingTimeInterval(MemoryCardScheduler.secondsPerDay)
  let card = makeCard(
    createdAt: now.addingTimeInterval(-MemoryCardScheduler.secondsPerDay),
    due: due,
    stability: 4.2,
    difficulty: 0.31,
    lastSeen: now.addingTimeInterval(-MemoryCardScheduler.secondsPerDay)
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
  let due = now.addingTimeInterval(-MemoryCardScheduler.secondsPerDay)
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
