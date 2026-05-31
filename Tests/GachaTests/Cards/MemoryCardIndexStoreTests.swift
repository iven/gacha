import Foundation
import GRDB
import Testing

@testable import Gacha

@Test func memoryCardIndexStoreCreatesDatabaseSchema() throws {
  let fixture = makeIndexFixture()
  _ = try fixture.indexStore()

  let dbQueue = try DatabaseQueue(path: fixture.directories.indexDatabaseURL.path)
  let tables = try dbQueue.read { database in
    try String.fetchAll(
      database,
      sql: """
        SELECT name FROM sqlite_master
        WHERE type = 'table' AND name = 'memory_cards'
        ORDER BY name
        """)
  }

  #expect(tables == ["memory_cards"])

  let columns = try dbQueue.read { database in
    try String.fetchAll(
      database,
      sql: "SELECT name FROM pragma_table_info('memory_cards') ORDER BY name")
  }

  #expect(columns.contains("display_title"))
  #expect(columns.contains("updated_at"))
  #expect(!columns.contains("title"))
}

@Test func memoryCardIndexStoreUpsertsAndListsCards() throws {
  let fixture = makeIndexFixture()
  let store = try fixture.indexStore()
  let first = makeMemoryCard(
    id: "20260523-150944-k7x4q9",
    body: "serendipity\n\nBody",
    directory: "english-vocabulary",
    createdAt: Date(timeIntervalSince1970: 1_779_548_984),
    updatedAt: Date(timeIntervalSince1970: 1_779_548_984))
  let second = makeMemoryCard(
    id: "20260523-151000-a1b2c3",
    body: "transience\n\nBody",
    directory: "philosophy",
    createdAt: Date(timeIntervalSince1970: 1_779_549_000),
    updatedAt: Date(timeIntervalSince1970: 1_779_549_000))

  try store.upsert(first, filePath: "english-vocabulary/\(first.id).md")
  try store.upsert(second, filePath: "philosophy/\(second.id).md")

  #expect(try store.count() == 2)
  #expect(try store.list().map(\.displayTitle) == ["transience", "serendipity"])
  #expect(try store.list(directory: "philosophy").map(\.displayTitle) == ["transience"])
}

@Test func memoryCardIndexStoreUpdatesExistingCard() throws {
  let fixture = makeIndexFixture()
  let store = try fixture.indexStore()
  var card = makeMemoryCard(
    id: "20260523-150944-k7x4q9",
    body: "Draft\n\nBody",
    directory: "Uncategorized")
  try store.upsert(card, filePath: "Uncategorized/\(card.id).md")

  card.body = "Final\n\nUpdated"
  card.stability = 4.2
  card.updatedAt = Date(timeIntervalSince1970: 1_779_549_000)
  try store.upsert(card, filePath: "Uncategorized/\(card.id).md")

  #expect(try store.count() == 1)
  #expect(try store.list() == [card])
}

@Test func memoryCardIndexStoreDeletesCards() throws {
  let fixture = makeIndexFixture()
  let store = try fixture.indexStore()
  let card = makeMemoryCard(id: "20260523-150944-k7x4q9", body: "Delete me\n\nBody")
  try store.upsert(card, filePath: "Uncategorized/\(card.id).md")

  try store.delete(id: card.id)

  #expect(try store.count() == 0)
  #expect(try store.list().isEmpty)
}

@Test func memoryCardIndexStoreRebuildsFromFileRepository() throws {
  let fixture = makeIndexFixture()
  let fileRepository = fixture.fileRepository()
  let store = try fixture.indexStore()

  try fileRepository.createDirectory(name: "english-vocabulary")
  try fileRepository.createDirectory(name: "philosophy")
  _ = try fileRepository.create(
    body: "serendipity\n\nA happy accident.",
    directory: "english-vocabulary")
  _ = try fileRepository.create(
    body: "transience\n\nThe state of not lasting.",
    directory: "philosophy")

  try store.rebuild(from: fileRepository)

  #expect(try store.count() == 2)
  #expect(try store.list().map(\.directory) == ["philosophy", "english-vocabulary"])
}

private struct MemoryCardIndexFixture {
  let directories: AppDirectories
  private let suffixes = SuffixSequence(["a1b2c3", "k7x4q9"])

  init() {
    let rootURL = URL(fileURLWithPath: "/tmp/agents/GachaTests/\(UUID().uuidString)")
    directories = AppDirectories(
      applicationSupportURL: rootURL.appendingPathComponent("Application Support"),
      userStorageURL: rootURL.appendingPathComponent("Documents"))
  }

  func indexStore() throws -> MemoryCardIndexStore {
    try MemoryCardIndexStore(databaseURL: directories.indexDatabaseURL)
  }

  func fileRepository() -> MemoryCardFileRepository {
    MemoryCardFileRepository(
      directories: directories,
      randomIDSuffix: { suffixes.next() },
      now: { Date(timeIntervalSince1970: 1_779_548_984) })
  }
}

private final class SuffixSequence {
  private var values: [String]

  init(_ values: [String]) {
    self.values = values
  }

  func next() -> String {
    values.removeFirst()
  }
}

private func makeIndexFixture() -> MemoryCardIndexFixture {
  MemoryCardIndexFixture()
}

private func makeMemoryCard(
  id: String,
  body: String,
  directory: String = "Uncategorized",
  createdAt: Date = Date(timeIntervalSince1970: 1_779_548_984),
  updatedAt: Date = Date(timeIntervalSince1970: 1_779_548_984)
) -> MemoryCard {
  MemoryCard(
    id: id,
    body: body,
    directory: directory,
    due: createdAt,
    stability: nil,
    difficulty: nil,
    lastSeen: nil,
    createdAt: createdAt,
    updatedAt: updatedAt)
}
