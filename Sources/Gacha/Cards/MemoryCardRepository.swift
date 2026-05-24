import Foundation

final class MemoryCardRepository {
  private let fileRepository: MemoryCardFileRepository
  private let indexStore: MemoryCardIndexStore

  init(
    fileRepository: MemoryCardFileRepository,
    indexStore: MemoryCardIndexStore
  ) {
    self.fileRepository = fileRepository
    self.indexStore = indexStore
  }

  convenience init(
    directories: AppDirectories,
    fileManager: FileManager = .default,
    randomIDSuffix: @escaping () -> String = MemoryCardFileRepository.makeRandomIDSuffix,
    now: @escaping () -> Date = Date.init
  ) throws {
    let fileRepository = MemoryCardFileRepository(
      directories: directories,
      fileManager: fileManager,
      randomIDSuffix: randomIDSuffix,
      now: now)
    let indexStore = try MemoryCardIndexStore(
      databaseURL: directories.indexDatabaseURL,
      fileManager: fileManager)
    self.init(fileRepository: fileRepository, indexStore: indexStore)
  }

  func prepareStorage() throws {
    try fileRepository.prepareStorage()
  }

  func createDirectory(name: String) throws {
    try fileRepository.createDirectory(name: name)
  }

  func renameDirectory(from oldName: String, to newName: String) throws {
    try fileRepository.renameDirectory(from: oldName, to: newName)
    try indexStore.renameDirectory(from: oldName, to: newName)
  }

  func deleteDirectory(name: String) throws {
    try fileRepository.deleteDirectory(name: name)
    try indexStore.deleteDirectory(name: name)
  }

  func create(
    body: String,
    directory: String = AppMetadata.defaultCategoryDirectoryName
  ) throws -> MemoryCard {
    let card = try fileRepository.create(body: body, directory: directory)
    try indexStore.upsert(card, filePath: card.relativeFilePath)
    return card
  }

  func write(_ card: MemoryCard) throws {
    if let existingCard = try indexStore.find(id: card.id) {
      if existingCard.directory != card.directory {
        try fileRepository.delete(id: existingCard.id, directory: existingCard.directory)
      }
    }

    try fileRepository.write(card)
    try indexStore.upsert(card, filePath: card.relativeFilePath)
  }

  func delete(id: String, directory: String) throws {
    try fileRepository.delete(id: id, directory: directory)
    try indexStore.delete(id: id)
  }

  func listDirectories() throws -> [String] {
    try fileRepository.listDirectories()
  }

  func list(directory: String? = nil) throws -> [MemoryCard] {
    try indexStore.list(directory: directory)
  }

  func count() throws -> Int {
    try indexStore.count()
  }

  func rebuildIndex() throws {
    try indexStore.rebuild(from: fileRepository)
  }
}
