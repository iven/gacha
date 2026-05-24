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
    body: "# serendipity\n\n/seren-dipity/\n\nA happy accident.")

  #expect(card.id == "20260523-150944-k7x4q9")
  #expect(card.directory == AppMetadata.defaultCategoryDirectoryName)
  #expect(card.due == createdAt)
  #expect(card.updatedAt == createdAt)
  #expect(card.displayTitle == "serendipity")

  let cardURL = fixture.directories.defaultMemoryCategoryURL
    .appendingPathComponent("\(card.id).md")
  let content = try String(contentsOf: cardURL, encoding: .utf8)

  #expect(content.contains("id: 20260523-150944-k7x4q9"))
  #expect(!content.contains("title:"))
  #expect(content.contains("updated_at:"))
  #expect(content.contains("/seren-dipity/"))
}

@Test func memoryCardRepositoryRoundTripsYamlEscapedMetadata() throws {
  let fixture = makeRepositoryFixture()

  _ = try fixture.repository.create(
    body: "term: \"serendipity\"\n\nA happy accident.")

  let cards = try fixture.repository.list()

  #expect(cards.map(\.displayTitle) == ["term: \"serendipity\""])
}

@Test func memoryCardRepositoryListsMarkdownCards() throws {
  let fixture = makeRepositoryFixture()
  let createdAt = Date(timeIntervalSince1970: 1_779_548_984)
  fixture.now = createdAt

  _ = try fixture.repository.create(
    body: "serendipity\n\nA happy accident.",
    directory: "english-vocabulary")
  _ = try fixture.repository.create(
    body: "transience\n\nThe state of not lasting.",
    directory: "philosophy")

  let cards = try fixture.repository.list()

  #expect(cards.map(\.displayTitle) == ["serendipity", "transience"])
  #expect(cards.map(\.directory) == ["english-vocabulary", "philosophy"])
  #expect(cards.allSatisfy { $0.kind == .memory })
}

@Test func memoryCardRepositoryListsCategoryDirectories() throws {
  let fixture = makeRepositoryFixture()

  try fixture.repository.prepareStorage()
  try fixture.fileManager.createDirectory(
    at: fixture.directories.memoryURL.appendingPathComponent("Product", isDirectory: true),
    withIntermediateDirectories: true)
  try fixture.fileManager.createDirectory(
    at: fixture.directories.memoryURL.appendingPathComponent("Swift", isDirectory: true),
    withIntermediateDirectories: true)

  let directories = try fixture.repository.listDirectories()

  #expect(directories == ["Product", "Swift", AppMetadata.defaultCategoryDirectoryName].sorted())
}

@Test func memoryCardRepositoryListDirectoriesDoesNotPrepareStorage() throws {
  let fixture = makeRepositoryFixture()

  let directories = try fixture.repository.listDirectories()

  #expect(directories.isEmpty)
  #expect(!fixture.fileManager.fileExists(atPath: fixture.directories.memoryURL.path))
}

@Test func memoryCardRepositoryUpdatesExistingCard() throws {
  let fixture = makeRepositoryFixture()
  let card = try fixture.repository.create(body: "Draft\n\nBefore")

  var updated = card
  updated.body = "Final\n\nAfter"
  updated.stability = 4.2
  updated.difficulty = 0.31
  updated.updatedAt = Date(timeIntervalSince1970: 1_779_549_000)
  try fixture.repository.write(updated)

  let cards = try fixture.repository.list()

  #expect(cards == [updated])
}

@Test func memoryCardRepositoryDeletesCardFile() throws {
  let fixture = makeRepositoryFixture()
  let card = try fixture.repository.create(body: "Delete me\n\nGone")

  try fixture.repository.delete(id: card.id, directory: card.directory)

  #expect(try fixture.repository.list().isEmpty)
}

@Test func memoryCardRepositoryCreatesCategoryDirectory() throws {
  let fixture = makeRepositoryFixture()

  try fixture.repository.createDirectory(name: "Product")

  let categoryURL = fixture.directories.memoryURL
    .appendingPathComponent("Product", isDirectory: true)
  #expect(fixture.fileManager.fileExists(atPath: categoryURL.path))
  #expect(try fixture.repository.listDirectories().contains("Product"))
}

@Test func memoryCardRepositoryRejectsDuplicateCategoryDirectory() throws {
  let fixture = makeRepositoryFixture()
  try fixture.repository.createDirectory(name: "Product")

  #expect(throws: MemoryCardFileRepositoryError.categoryAlreadyExists("Product")) {
    try fixture.repository.createDirectory(name: "Product")
  }
}

@Test func memoryCardRepositoryRejectsInvalidNewCategoryNames() throws {
  let fixture = makeRepositoryFixture()

  #expect(throws: MemoryCardFileRepositoryError.invalidCategoryName("bad/name")) {
    try fixture.repository.createDirectory(name: "bad/name")
  }
}

@Test func memoryCardRepositoryRenamesCategoryDirectory() throws {
  let fixture = makeRepositoryFixture()
  try fixture.repository.createDirectory(name: "Product")

  try fixture.repository.renameDirectory(from: "Product", to: "Strategy")

  let oldURL = fixture.directories.memoryURL
    .appendingPathComponent("Product", isDirectory: true)
  let newURL = fixture.directories.memoryURL
    .appendingPathComponent("Strategy", isDirectory: true)
  #expect(!fixture.fileManager.fileExists(atPath: oldURL.path))
  #expect(fixture.fileManager.fileExists(atPath: newURL.path))
}

@Test func memoryCardRepositoryRejectsRenamingDefaultCategory() throws {
  let fixture = makeRepositoryFixture()
  try fixture.repository.prepareStorage()

  #expect(
    throws: MemoryCardFileRepositoryError.categoryNotRenamable(
      AppMetadata.defaultCategoryDirectoryName)
  ) {
    try fixture.repository.renameDirectory(
      from: AppMetadata.defaultCategoryDirectoryName,
      to: "Anything")
  }
}

@Test func memoryCardRepositoryRejectsRenameToExistingCategory() throws {
  let fixture = makeRepositoryFixture()
  try fixture.repository.createDirectory(name: "Product")
  try fixture.repository.createDirectory(name: "Strategy")

  #expect(throws: MemoryCardFileRepositoryError.categoryAlreadyExists("Strategy")) {
    try fixture.repository.renameDirectory(from: "Product", to: "Strategy")
  }
}

@Test func memoryCardRepositoryRejectsRenameOfMissingCategory() throws {
  let fixture = makeRepositoryFixture()
  try fixture.repository.prepareStorage()

  #expect(throws: MemoryCardFileRepositoryError.categoryNotFound("Missing")) {
    try fixture.repository.renameDirectory(from: "Missing", to: "Anything")
  }
}

@Test func memoryCardRepositoryRejectsInvalidCategoryNames() throws {
  let fixture = makeRepositoryFixture()

  #expect(throws: MemoryCardFileRepositoryError.invalidCategoryName("_meta")) {
    _ = try fixture.repository.create(body: "", directory: "_meta")
  }
  #expect(throws: MemoryCardFileRepositoryError.invalidCategoryName("bad/name")) {
    _ = try fixture.repository.create(body: "", directory: "bad/name")
  }
}

@Test func memoryCardRepositoryRejectsInvalidCardIDsOnWrite() throws {
  let fixture = makeRepositoryFixture()
  let card = MemoryCard(
    id: "../outside",
    body: "",
    directory: AppMetadata.defaultCategoryDirectoryName,
    due: nil,
    stability: nil,
    difficulty: nil,
    lastSeen: nil,
    createdAt: fixture.now,
    updatedAt: fixture.now)

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
