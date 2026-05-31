import Foundation
import Testing

@testable import Gacha

@Test func memoryCardRepositoryCreatesFileAndIndexRecord() throws {
  let fixture = makeMemoryCardRepositoryFixture()
  fixture.now = Date(timeIntervalSince1970: 1_779_548_984)
  let repository = try fixture.repository()

  try repository.createDirectory(name: "english-vocabulary")
  let card = try repository.create(
    body: "serendipity\n\nA happy accident.",
    directory: "english-vocabulary")

  let cardURL = fixture.directories.memoryURL
    .appendingPathComponent("english-vocabulary", isDirectory: true)
    .appendingPathComponent("\(card.id).md")
  #expect(fixture.fileManager.fileExists(atPath: cardURL.path))
  try #expect(repository.count() == 1)
  try #expect(repository.list() == [card])
}

@Test func memoryCardRepositoryUpdatesFileAndIndexRecord() throws {
  let fixture = makeMemoryCardRepositoryFixture()
  let repository = try fixture.repository()
  var card = try repository.create(body: "Draft\n\nBefore")

  card.body = "Final\n\nAfter"
  card.stability = 4.2
  card.updatedAt = Date(timeIntervalSince1970: 1_779_549_000)
  try repository.write(card)

  let cardURL = fixture.directories.defaultMemoryCategoryURL
    .appendingPathComponent("\(card.id).md")
  let content = try String(contentsOf: cardURL, encoding: .utf8)

  #expect(!content.contains("title:"))
  #expect(content.contains("updated_at:"))
  #expect(content.contains("After"))
  try #expect(repository.list() == [card])
}

@Test func memoryCardRepositoryRemovesOldFileWhenCardMovesDirectory() throws {
  let fixture = makeMemoryCardRepositoryFixture()
  let repository = try fixture.repository()
  var card = try repository.create(body: "Move me\n\nBefore")
  let oldCardURL = fixture.directories.defaultMemoryCategoryURL
    .appendingPathComponent("\(card.id).md")

  try repository.createDirectory(name: "philosophy")
  card.directory = "philosophy"
  card.body = "After"
  try repository.write(card)

  let newCardURL = fixture.directories.memoryURL
    .appendingPathComponent("philosophy", isDirectory: true)
    .appendingPathComponent("\(card.id).md")

  #expect(!fixture.fileManager.fileExists(atPath: oldCardURL.path))
  #expect(fixture.fileManager.fileExists(atPath: newCardURL.path))

  try repository.rebuildIndex()

  try #expect(repository.count() == 1)
  try #expect(repository.list() == [card])
}

@Test func memoryCardRepositoryDeletesFileAndIndexRecord() throws {
  let fixture = makeMemoryCardRepositoryFixture()
  let repository = try fixture.repository()
  let card = try repository.create(body: "Delete me\n\nGone")
  let cardURL = fixture.directories.defaultMemoryCategoryURL
    .appendingPathComponent("\(card.id).md")

  try repository.delete(id: card.id, directory: card.directory)

  #expect(!fixture.fileManager.fileExists(atPath: cardURL.path))
  try #expect(repository.count() == 0)
  try #expect(repository.list().isEmpty)
}

@Test func memoryCardRepositoryListsFromIndexByDirectory() throws {
  let fixture = makeMemoryCardRepositoryFixture()
  let repository = try fixture.repository()

  try repository.createDirectory(name: "english-vocabulary")
  try repository.createDirectory(name: "philosophy")
  _ = try repository.create(
    body: "serendipity\n\nA happy accident.",
    directory: "english-vocabulary")
  _ = try repository.create(
    body: "transience\n\nThe state of not lasting.",
    directory: "philosophy")

  try #expect(repository.list(directory: "philosophy").map(\.displayTitle) == ["transience"])
}

@Test func memoryCardRepositoryRenamesDirectoryAcrossFilesAndIndex() throws {
  let fixture = makeMemoryCardRepositoryFixture()
  let repository = try fixture.repository()

  try repository.createDirectory(name: "Product")
  let card = try repository.create(
    body: "serendipity\n\nA happy accident.",
    directory: "Product")

  try repository.renameDirectory(from: "Product", to: "Strategy")

  let oldURL = fixture.directories.memoryURL
    .appendingPathComponent("Product", isDirectory: true)
    .appendingPathComponent("\(card.id).md")
  let newURL = fixture.directories.memoryURL
    .appendingPathComponent("Strategy", isDirectory: true)
    .appendingPathComponent("\(card.id).md")

  #expect(!fixture.fileManager.fileExists(atPath: oldURL.path))
  #expect(fixture.fileManager.fileExists(atPath: newURL.path))

  let cards = try repository.list(directory: "Strategy")
  #expect(cards.map(\.id) == [card.id])
  #expect(cards.allSatisfy { $0.directory == "Strategy" })
  #expect(throws: MemoryCardFileRepositoryError.categoryNotFound("Product")) {
    try repository.list(directory: "Product")
  }
}

@Test func memoryCardRepositoryDeletesCategoryAndItsCards() throws {
  let fixture = makeMemoryCardRepositoryFixture()
  let repository = try fixture.repository()

  try repository.createDirectory(name: "Product")
  try repository.createDirectory(name: "Strategy")
  _ = try repository.create(body: "first\n\nbody", directory: "Product")
  _ = try repository.create(body: "second\n\nbody", directory: "Product")
  _ = try repository.create(body: "kept\n\nbody", directory: "Strategy")

  try repository.deleteDirectory(name: "Product")

  let categoryURL = fixture.directories.memoryURL
    .appendingPathComponent("Product", isDirectory: true)
  #expect(!fixture.fileManager.fileExists(atPath: categoryURL.path))
  #expect(throws: MemoryCardFileRepositoryError.categoryNotFound("Product")) {
    try repository.list(directory: "Product")
  }
  try #expect(repository.list(directory: "Strategy").map(\.displayTitle) == ["kept"])
  try #expect(repository.count() == 1)
}

@Test func memoryCardRepositoryRebuildsIndexFromFiles() throws {
  let fixture = makeMemoryCardRepositoryFixture()
  let repository = try fixture.repository()
  _ = try fixture.writeCardFile(
    body: "serendipity\n\nA happy accident.",
    directory: "english-vocabulary")
  _ = try fixture.writeCardFile(
    body: "transience\n\nThe state of not lasting.",
    directory: "philosophy")

  try repository.rebuildIndex()

  try #expect(repository.count() == 2)
  try #expect(repository.list().map(\.displayTitle) == ["transience", "serendipity"])
}

@Test func memoryCardRepositoryEmitsRebuildIndexEvent() throws {
  let fixture = makeMemoryCardRepositoryFixture()
  let repository = try fixture.repository()
  _ = try fixture.writeCardFile(body: "first\n\nbody", directory: "Product")
  var observed: [MemoryCardRepositoryEvent] = []
  let cancellable = repository.events.sink { observed.append($0) }
  defer { cancellable.cancel() }

  try repository.rebuildIndex()

  #expect(observed == [.didRebuildIndex])
}

@Test func memoryCardRepositoryEmitsEventsForLifecycle() throws {
  let fixture = makeMemoryCardRepositoryFixture()
  let repository = try fixture.repository()
  var observed: [MemoryCardRepositoryEvent] = []
  let cancellable = repository.events.sink { observed.append($0) }
  defer { cancellable.cancel() }

  try repository.createDirectory(name: "Product")
  let created = try repository.create(body: "first\n\nbody", directory: "Product")
  var updated = created
  updated.body = "first\n\nupdated"
  try repository.write(updated)
  try repository.renameDirectory(from: "Product", to: "Renamed")
  try repository.delete(id: updated.id, directory: "Renamed")
  try repository.deleteDirectory(name: "Renamed")

  #expect(
    observed
      == [
        .didCreateDirectory(name: "Product"),
        .didCreate(created, focusEditor: false),
        .didUpdate(updated),
        .didMoveDirectory(from: "Product", to: "Renamed"),
        .didDelete(id: updated.id, directory: "Renamed"),
        .didDeleteDirectory(name: "Renamed"),
      ])
}

@Test func memoryCardRepositoryForwardsFocusEditorFlagOnCreate() throws {
  let fixture = makeMemoryCardRepositoryFixture()
  let repository = try fixture.repository()
  var observed: [MemoryCardRepositoryEvent] = []
  let cancellable = repository.events.sink { observed.append($0) }
  defer { cancellable.cancel() }

  let card = try repository.create(
    body: "focus me\n\nbody",
    directory: AppMetadata.defaultCategoryDirectoryName,
    focusEditor: true)

  #expect(observed == [.didCreate(card, focusEditor: true)])
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
    body: String,
    directory: String
  ) throws -> MemoryCard {
    let fileRepository = MemoryCardFileRepository(
      directories: directories,
      fileManager: fileManager,
      randomIDSuffix: { self.fileSuffixes.next() },
      now: { self.now })
    try? fileRepository.createDirectory(name: directory)
    return try fileRepository.create(body: body, directory: directory)
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
