import Foundation
import Testing

@testable import Gacha

@Test func memoryCardRepositoryPreparesDirectoryTree() throws {
  let fixture = makeRepositoryFixture()

  try fixture.repository.prepareStorage()

  #expect(fixture.fileManager.fileExists(atPath: fixture.directories.applicationSupportURL.path))
  #expect(fixture.fileManager.fileExists(atPath: fixture.directories.memoryURL.path))
  #expect(fixture.fileManager.fileExists(atPath: fixture.directories.defaultMemoryCategoryURL.path))
}

@Test func memoryCardRepositoryCreatesMarkdownCard() throws {
  let fixture = makeRepositoryFixture()
  let createdAt = Date(timeIntervalSince1970: 1_779_548_984)
  fixture.now = createdAt

  let card = try fixture.repository.create(
    title: "serendipity",
    body: "/seren-dipity/\n\nA happy accident.")

  #expect(card.id == "20260523-150944-k7x4q9")
  #expect(card.directory == AppMetadata.defaultCategoryDirectoryName)
  #expect(card.due == createdAt)

  let cardURL = fixture.directories.defaultMemoryCategoryURL
    .appendingPathComponent("\(card.id).md")
  let content = try String(contentsOf: cardURL, encoding: .utf8)

  #expect(content.contains("id: 20260523-150944-k7x4q9"))
  #expect(content.contains("title: serendipity"))
  #expect(content.contains("/seren-dipity/"))
}

@Test func memoryCardRepositoryRoundTripsYamlEscapedMetadata() throws {
  let fixture = makeRepositoryFixture()

  _ = try fixture.repository.create(
    title: "term: \"serendipity\"",
    body: "A happy accident.")

  let cards = try fixture.repository.list()

  #expect(cards.map(\.title) == ["term: \"serendipity\""])
}

@Test func memoryCardRepositoryListsMarkdownCards() throws {
  let fixture = makeRepositoryFixture()
  let createdAt = Date(timeIntervalSince1970: 1_779_548_984)
  fixture.now = createdAt

  _ = try fixture.repository.create(
    title: "serendipity",
    body: "A happy accident.",
    directory: "english-vocabulary")
  _ = try fixture.repository.create(
    title: "transience",
    body: "The state of not lasting.",
    directory: "philosophy")

  let cards = try fixture.repository.list()

  #expect(cards.map(\.title) == ["serendipity", "transience"])
  #expect(cards.map(\.directory) == ["english-vocabulary", "philosophy"])
  #expect(cards.allSatisfy { $0.kind == .memory })
}

@Test func memoryCardRepositoryUpdatesExistingCard() throws {
  let fixture = makeRepositoryFixture()
  let card = try fixture.repository.create(title: "Draft", body: "Before")

  var updated = card
  updated.title = "Final"
  updated.body = "After"
  updated.stability = 4.2
  updated.difficulty = 0.31
  try fixture.repository.write(updated)

  let cards = try fixture.repository.list()

  #expect(cards == [updated])
}

@Test func memoryCardRepositoryDeletesCardFile() throws {
  let fixture = makeRepositoryFixture()
  let card = try fixture.repository.create(title: "Delete me", body: "Gone")

  try fixture.repository.delete(id: card.id, directory: card.directory)

  #expect(try fixture.repository.list().isEmpty)
}

@Test func memoryCardRepositoryRejectsInvalidCategoryNames() throws {
  let fixture = makeRepositoryFixture()

  #expect(throws: MemoryCardFileRepositoryError.invalidCategoryName("_meta")) {
    _ = try fixture.repository.create(title: "Invalid", body: "", directory: "_meta")
  }
  #expect(throws: MemoryCardFileRepositoryError.invalidCategoryName("bad/name")) {
    _ = try fixture.repository.create(title: "Invalid", body: "", directory: "bad/name")
  }
}

@Test func memoryCardRepositoryRejectsInvalidCardIDsOnWrite() throws {
  let fixture = makeRepositoryFixture()
  let card = MemoryCard(
    id: "../outside",
    title: "Invalid",
    body: "",
    directory: AppMetadata.defaultCategoryDirectoryName,
    due: nil,
    stability: nil,
    difficulty: nil,
    lastSeen: nil,
    createdAt: fixture.now)

  #expect(throws: MemoryCardFileRepositoryError.invalidCardID("../outside")) {
    try fixture.repository.write(card)
  }
}

@Test func memoryCardRepositoryRejectsInvalidDeletePathArguments() throws {
  let fixture = makeRepositoryFixture()

  #expect(throws: MemoryCardFileRepositoryError.invalidCategoryName("../outside")) {
    try fixture.repository.delete(id: "card", directory: "../outside")
  }
  #expect(throws: MemoryCardFileRepositoryError.invalidCardID("../outside")) {
    try fixture.repository.delete(
      id: "../outside",
      directory: AppMetadata.defaultCategoryDirectoryName)
  }
}

private final class MemoryCardRepositoryFixture {
  let fileManager = FileManager.default
  let directories: AppDirectories
  var now = Date(timeIntervalSince1970: 1_779_548_984)
  lazy var repository = MemoryCardFileRepository(
    directories: directories,
    fileManager: fileManager,
    randomIDSuffix: { "k7x4q9" },
    now: { self.now })

  init() {
    let rootURL = URL(fileURLWithPath: "/tmp/agents/GachaTests/\(UUID().uuidString)")
    directories = AppDirectories(
      applicationSupportURL: rootURL.appendingPathComponent("Application Support"),
      userStorageURL: rootURL.appendingPathComponent("Documents"))
  }
}

private func makeRepositoryFixture() -> MemoryCardRepositoryFixture {
  MemoryCardRepositoryFixture()
}
