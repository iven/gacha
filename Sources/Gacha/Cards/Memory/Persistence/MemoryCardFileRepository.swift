import Foundation

enum MemoryCardFileRepositoryError: Error, Equatable {
  case invalidCategoryName(String)
  case categoryAlreadyExists(String)
  case categoryNotFound(String)
  case categoryNotRenamable(String)
  case categoryNotDeletable(String)
  case invalidCardID(String)
  case missingFrontMatter(URL)
}

final class MemoryCardFileRepository {
  private let directories: AppDirectories
  private let fileManager: FileManager
  private let randomIDSuffix: () -> String
  private let now: () -> Date

  init(
    directories: AppDirectories,
    fileManager: FileManager = .default,
    randomIDSuffix: @escaping () -> String = MemoryCardIDGenerator.makeRandomSuffix,
    now: @escaping () -> Date = Date.init
  ) {
    self.directories = directories
    self.fileManager = fileManager
    self.randomIDSuffix = randomIDSuffix
    self.now = now
  }

  func prepareStorage() throws {
    try fileManager.createDirectory(
      at: directories.defaultMemoryCategoryURL,
      withIntermediateDirectories: true)
  }

  func create(
    body: String,
    directory: String = AppMetadata.defaultCategoryDirectoryName
  ) throws -> MemoryCard {
    try validateCategoryName(directory)
    try prepareStorage()

    let createdAt = now()
    let card = MemoryCard(
      id: MemoryCardIDGenerator.make(createdAt: createdAt, randomSuffix: randomIDSuffix),
      body: body,
      directory: directory,
      due: createdAt,
      stability: nil,
      difficulty: nil,
      lastSeen: nil,
      createdAt: createdAt,
      updatedAt: createdAt)
    try write(card)
    return card
  }

  func write(_ card: MemoryCard) throws {
    try validateCategoryName(card.directory)
    try validateCardID(card.id)

    let categoryURL = directories.memoryURL.appendingPathComponent(
      card.directory,
      isDirectory: true)
    guard fileManager.fileExists(atPath: categoryURL.path) else {
      throw MemoryCardFileRepositoryError.categoryNotFound(card.directory)
    }
    try MemoryCardMarkdownCodec.encode(card).write(
      to: fileURL(for: card),
      atomically: true,
      encoding: .utf8)
  }

  func createDirectory(name: String) throws {
    try validateCategoryName(name)
    try prepareStorage()

    let categoryURL = directories.memoryURL.appendingPathComponent(name, isDirectory: true)
    if fileManager.fileExists(atPath: categoryURL.path) {
      throw MemoryCardFileRepositoryError.categoryAlreadyExists(name)
    }

    try fileManager.createDirectory(at: categoryURL, withIntermediateDirectories: true)
  }

  func deleteDirectory(name: String) throws {
    try validateCategoryName(name)

    if name == AppMetadata.defaultCategoryDirectoryName {
      throw MemoryCardFileRepositoryError.categoryNotDeletable(name)
    }

    let categoryURL = directories.memoryURL.appendingPathComponent(name, isDirectory: true)
    guard fileManager.fileExists(atPath: categoryURL.path) else {
      throw MemoryCardFileRepositoryError.categoryNotFound(name)
    }

    try fileManager.removeItem(at: categoryURL)
  }

  func renameDirectory(from oldName: String, to newName: String) throws {
    try validateCategoryName(oldName)
    try validateCategoryName(newName)

    if oldName == AppMetadata.defaultCategoryDirectoryName {
      throw MemoryCardFileRepositoryError.categoryNotRenamable(oldName)
    }

    if oldName == newName {
      return
    }

    let oldURL = directories.memoryURL.appendingPathComponent(oldName, isDirectory: true)
    let newURL = directories.memoryURL.appendingPathComponent(newName, isDirectory: true)

    guard fileManager.fileExists(atPath: oldURL.path) else {
      throw MemoryCardFileRepositoryError.categoryNotFound(oldName)
    }
    if fileManager.fileExists(atPath: newURL.path) {
      throw MemoryCardFileRepositoryError.categoryAlreadyExists(newName)
    }

    try fileManager.moveItem(at: oldURL, to: newURL)
  }

  func delete(id: String, directory: String) throws {
    try validateCategoryName(directory)
    try validateCardID(id)

    let categoryURL = directories.memoryURL.appendingPathComponent(directory, isDirectory: true)
    guard fileManager.fileExists(atPath: categoryURL.path) else {
      throw MemoryCardFileRepositoryError.categoryNotFound(directory)
    }

    let fileURL = directories.memoryURL
      .appendingPathComponent(directory, isDirectory: true)
      .appendingPathComponent("\(id).md")
    guard fileManager.fileExists(atPath: fileURL.path) else {
      throw MemoryCardFileRepositoryError.invalidCardID(id)
    }

    try fileManager.removeItem(at: fileURL)
  }

  func listDirectories() throws -> [String] {
    guard fileManager.fileExists(atPath: directories.memoryURL.path) else {
      return []
    }

    let categoryURLs = try fileManager.contentsOfDirectory(
      at: directories.memoryURL,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles])

    let directories = try categoryURLs.compactMap { url -> String? in
      guard try isVisibleDirectory(url) else {
        return nil
      }

      return url.lastPathComponent
    }

    return directories.sorted()
  }

  func list() throws -> [MemoryCard] {
    guard fileManager.fileExists(atPath: directories.memoryURL.path) else {
      return []
    }

    let categoryURLs = try fileManager.contentsOfDirectory(
      at: directories.memoryURL,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles])

    var cards: [MemoryCard] = []
    for categoryURL in categoryURLs where try isVisibleDirectory(categoryURL) {
      let fileURLs = try fileManager.contentsOfDirectory(
        at: categoryURL,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles])

      for fileURL in fileURLs where shouldScanCardFile(fileURL) {
        cards.append(try read(fileURL: fileURL))
      }
    }

    return cards.sorted { lhs, rhs in
      if lhs.createdAt == rhs.createdAt {
        return lhs.id < rhs.id
      }
      return lhs.createdAt < rhs.createdAt
    }
  }

  func read(fileURL: URL) throws -> MemoryCard {
    let content = try String(contentsOf: fileURL, encoding: .utf8)
    do {
      return try MemoryCardMarkdownCodec.decode(
        content: content,
        fileURL: fileURL,
        fallbackDate: now())
    } catch MemoryCardMarkdownCodecError.missingFrontMatter(let url) {
      throw MemoryCardFileRepositoryError.missingFrontMatter(url)
    }
  }

  static func isValidCategoryName(_ name: String) -> Bool {
    !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && name.count <= 100
      && !name.hasPrefix(".")
      && !name.hasPrefix("_")
      && !name.contains("/")
      && !name.contains(":")
      && !name.contains("\\")
  }

  private func fileURL(for card: MemoryCard) -> URL {
    directories.memoryURL
      .appendingPathComponent(card.directory, isDirectory: true)
      .appendingPathComponent("\(card.id).md")
  }

  private func validateCategoryName(_ name: String) throws {
    guard Self.isValidCategoryName(name) else {
      throw MemoryCardFileRepositoryError.invalidCategoryName(name)
    }
  }

  private func validateCardID(_ id: String) throws {
    guard MemoryCardIDGenerator.isValid(id) else {
      throw MemoryCardFileRepositoryError.invalidCardID(id)
    }
  }

  private func isVisibleDirectory(_ url: URL) throws -> Bool {
    guard !url.lastPathComponent.hasPrefix("_") else {
      return false
    }

    let values = try url.resourceValues(forKeys: [.isDirectoryKey])
    return values.isDirectory == true
  }

  private func shouldScanCardFile(_ url: URL) -> Bool {
    let name = url.lastPathComponent
    return url.pathExtension == "md" && !name.hasPrefix(".") && !name.hasPrefix("_")
  }
}
