import Foundation
import Testing

@testable import Gacha

@Test func memoryCardRepositoryCreatesFileAndIndexRecord() throws {
  let fixture = makeMemoryCardRepositoryFixture()
  fixture.now = Date(timeIntervalSince1970: 1_779_548_984)
  let repository = try fixture.repository()

  let card = try repository.create(
    title: "serendipity",
    body: "A happy accident.",
    directory: "english-vocabulary")

  let cardURL = fixture.directories.memoryURL
    .appendingPathComponent("english-vocabulary", isDirectory: true)
    .appendingPathComponent("\(card.id).md")
  #expect(fixture.fileManager.fileExists(atPath: cardURL.path))
  #expect(try repository.count() == 1)
  #expect(try repository.list() == [card])
}

@Test func memoryCardRepositoryUpdatesFileAndIndexRecord() throws {
  let fixture = makeMemoryCardRepositoryFixture()
  let repository = try fixture.repository()
  var card = try repository.create(title: "Draft", body: "Before")

  card.title = "Final"
  card.body = "After"
  card.stability = 4.2
  try repository.write(card)

  let cardURL = fixture.directories.defaultMemoryCategoryURL
    .appendingPathComponent("\(card.id).md")
  let content = try String(contentsOf: cardURL, encoding: .utf8)

  #expect(content.contains("title: Final"))
  #expect(content.contains("After"))
  #expect(try repository.list() == [card])
}

@Test func memoryCardRepositoryRemovesOldFileWhenCardMovesDirectory() throws {
  let fixture = makeMemoryCardRepositoryFixture()
  let repository = try fixture.repository()
  var card = try repository.create(title: "Move me", body: "Before")
  let oldCardURL = fixture.directories.defaultMemoryCategoryURL
    .appendingPathComponent("\(card.id).md")

  card.directory = "philosophy"
  card.body = "After"
  try repository.write(card)

  let newCardURL = fixture.directories.memoryURL
    .appendingPathComponent("philosophy", isDirectory: true)
    .appendingPathComponent("\(card.id).md")

  #expect(!fixture.fileManager.fileExists(atPath: oldCardURL.path))
  #expect(fixture.fileManager.fileExists(atPath: newCardURL.path))

  try repository.rebuildIndex()

  #expect(try repository.count() == 1)
  #expect(try repository.list() == [card])
}

@Test func memoryCardRepositoryDeletesFileAndIndexRecord() throws {
  let fixture = makeMemoryCardRepositoryFixture()
  let repository = try fixture.repository()
  let card = try repository.create(title: "Delete me", body: "Gone")
  let cardURL = fixture.directories.defaultMemoryCategoryURL
    .appendingPathComponent("\(card.id).md")

  try repository.delete(id: card.id, directory: card.directory)

  #expect(!fixture.fileManager.fileExists(atPath: cardURL.path))
  #expect(try repository.count() == 0)
  #expect(try repository.list().isEmpty)
}

@Test func memoryCardRepositoryListsFromIndexByDirectory() throws {
  let fixture = makeMemoryCardRepositoryFixture()
  let repository = try fixture.repository()

  _ = try repository.create(
    title: "serendipity",
    body: "A happy accident.",
    directory: "english-vocabulary")
  _ = try repository.create(
    title: "transience",
    body: "The state of not lasting.",
    directory: "philosophy")

  #expect(try repository.list(directory: "philosophy").map(\.title) == ["transience"])
}

@Test func memoryCardRepositoryRebuildsIndexFromFiles() throws {
  let fixture = makeMemoryCardRepositoryFixture()
  let repository = try fixture.repository()
  _ = try fixture.writeCardFile(
    title: "serendipity",
    body: "A happy accident.",
    directory: "english-vocabulary")
  _ = try fixture.writeCardFile(
    title: "transience",
    body: "The state of not lasting.",
    directory: "philosophy")

  try repository.rebuildIndex()

  #expect(try repository.count() == 2)
  #expect(try repository.list().map(\.title) == ["serendipity", "transience"])
}

private final class MemoryCardRepositoryFacadeFixture {
  let fileManager = FileManager.default
  let directories: AppDirectories
  private let rootURL: URL
  private let repositorySuffixes = MemoryCardRepositorySuffixSequence([
    "a1b2c3",
    "k7x4q9",
    "z9y8x7",
  ])
  private let fileSuffixes = MemoryCardRepositorySuffixSequence([
    "m1n2p3",
    "q4r5s6",
    "t7u8v9",
  ])
  var now = Date(timeIntervalSince1970: 1_779_548_984)

  init() {
    rootURL = URL(fileURLWithPath: "/tmp/agents/GachaTests/\(UUID().uuidString)")
    directories = AppDirectories(
      applicationSupportURL: rootURL.appendingPathComponent("Application Support"),
      userStorageURL: rootURL.appendingPathComponent("Documents"))
  }

  deinit {
    try? fileManager.removeItem(at: rootURL)
  }

  func repository() throws -> MemoryCardRepository {
    try MemoryCardRepository(
      directories: directories,
      fileManager: fileManager,
      randomIDSuffix: { self.repositorySuffixes.next() },
      now: { self.now })
  }

  func writeCardFile(
    title: String,
    body: String,
    directory: String
  ) throws -> MemoryCard {
    let fileRepository = MemoryCardFileRepository(
      directories: directories,
      fileManager: fileManager,
      randomIDSuffix: { self.fileSuffixes.next() },
      now: { self.now })
    return try fileRepository.create(title: title, body: body, directory: directory)
  }
}

private final class MemoryCardRepositorySuffixSequence {
  private var values: [String]

  init(_ values: [String]) {
    self.values = values
  }

  func next() -> String {
    values.removeFirst()
  }
}

private func makeMemoryCardRepositoryFixture() -> MemoryCardRepositoryFacadeFixture {
  MemoryCardRepositoryFacadeFixture()
}
