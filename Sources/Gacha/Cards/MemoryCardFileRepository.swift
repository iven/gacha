import Foundation
import Yams

enum MemoryCardFileRepositoryError: Error, Equatable {
  case invalidCategoryName(String)
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
    randomIDSuffix: @escaping () -> String = MemoryCardFileRepository.makeRandomIDSuffix,
    now: @escaping () -> Date = Date.init
  ) {
    self.directories = directories
    self.fileManager = fileManager
    self.randomIDSuffix = randomIDSuffix
    self.now = now
  }

  func prepareStorage() throws {
    try fileManager.createDirectory(
      at: directories.applicationSupportURL,
      withIntermediateDirectories: true)
    try fileManager.createDirectory(
      at: directories.defaultMemoryCategoryURL,
      withIntermediateDirectories: true)
  }

  func create(
    title: String,
    body: String,
    directory: String = AppMetadata.defaultCategoryDirectoryName
  ) throws -> MemoryCard {
    try validateCategoryName(directory)
    try prepareStorage()

    let createdAt = now()
    let card = MemoryCard(
      id: makeCardID(createdAt: createdAt),
      title: title,
      body: body,
      directory: directory,
      due: createdAt,
      stability: nil,
      difficulty: nil,
      lastSeen: nil,
      createdAt: createdAt)
    try write(card)
    return card
  }

  func write(_ card: MemoryCard) throws {
    try validateCategoryName(card.directory)
    try validateCardID(card.id)

    let categoryURL = directories.memoryURL.appendingPathComponent(
      card.directory,
      isDirectory: true)
    try fileManager.createDirectory(at: categoryURL, withIntermediateDirectories: true)
    try markdown(for: card).write(
      to: fileURL(for: card),
      atomically: true,
      encoding: .utf8)
  }

  func delete(id: String, directory: String) throws {
    try validateCategoryName(directory)
    try validateCardID(id)

    try fileManager.removeItem(
      at: directories.memoryURL
        .appendingPathComponent(directory, isDirectory: true)
        .appendingPathComponent("\(id).md"))
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
    guard content.hasPrefix("---\n") else {
      throw MemoryCardFileRepositoryError.missingFrontMatter(fileURL)
    }

    let metadataStart = content.index(content.startIndex, offsetBy: 4)
    guard metadataStart < content.endIndex else {
      throw MemoryCardFileRepositoryError.missingFrontMatter(fileURL)
    }

    let metadataSearchRange = metadataStart..<content.endIndex
    guard let endRange = content.range(of: "\n---\n", range: metadataSearchRange) else {
      throw MemoryCardFileRepositoryError.missingFrontMatter(fileURL)
    }

    let metadataYAML = String(content[metadataStart..<endRange.lowerBound])
    let bodyStart = markdownBodyStart(in: content, after: endRange)
    let body = String(content[bodyStart...])
    let metadata = try YAMLDecoder().decode(MemoryCardMetadata.self, from: metadataYAML)

    return MemoryCard(
      id: metadata.id,
      title: metadata.title,
      body: body,
      directory: fileURL.deletingLastPathComponent().lastPathComponent,
      due: metadata.due.flatMap(parseDate),
      stability: metadata.stability,
      difficulty: metadata.difficulty,
      lastSeen: metadata.lastSeen.flatMap(parseDate),
      createdAt: parseDate(metadata.createdAt) ?? now())
  }
}

extension MemoryCardFileRepository {
  private func fileURL(for card: MemoryCard) -> URL {
    directories.memoryURL
      .appendingPathComponent(card.directory, isDirectory: true)
      .appendingPathComponent("\(card.id).md")
  }

  private func markdownBodyStart(
    in content: String,
    after frontMatterEndRange: Range<String.Index>
  ) -> String.Index {
    let bodyStart = frontMatterEndRange.upperBound
    guard bodyStart < content.endIndex, content[bodyStart] == "\n" else {
      return bodyStart
    }

    return content.index(after: bodyStart)
  }

  private func validateCategoryName(_ name: String) throws {
    guard
      !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
      name.count <= 100,
      !name.hasPrefix("."),
      !name.hasPrefix("_"),
      !name.contains("/"),
      !name.contains(":"),
      !name.contains("\\")
    else {
      throw MemoryCardFileRepositoryError.invalidCategoryName(name)
    }
  }

  private func validateCardID(_ id: String) throws {
    guard Self.isValidCardID(id) else {
      throw MemoryCardFileRepositoryError.invalidCardID(id)
    }
  }

  private func makeCardID(createdAt: Date) -> String {
    "\(formatIDTimestamp(createdAt))-\(randomIDSuffix())"
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

  private func markdown(for card: MemoryCard) throws -> String {
    let metadata = MemoryCardMetadata(card: card, formatDate: formatDate)
    let yaml = try YAMLEncoder().encode(metadata)
    return [
      "---",
      yaml.trimmingCharacters(in: .newlines),
      "---",
      "",
      card.body,
    ].joined(separator: "\n")
  }

  private func formatDate(_ date: Date) -> String {
    dateFormatter(includingFractionalSeconds: true).string(from: date)
  }

  private func formatIDTimestamp(_ date: Date) -> String {
    Self.idTimestampFormatter.string(from: date)
  }

  private func parseDate(_ value: String) -> Date? {
    dateFormatter(includingFractionalSeconds: true).date(from: value)
      ?? dateFormatter(includingFractionalSeconds: false).date(from: value)
  }

  private func dateFormatter(includingFractionalSeconds: Bool) -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions =
      includingFractionalSeconds
      ? [.withInternetDateTime, .withFractionalSeconds]
      : [.withInternetDateTime]
    return formatter
  }

  private static func isValidCardID(_ id: String) -> Bool {
    let characters = Array(id)
    guard characters.count == 22, characters[8] == "-", characters[15] == "-" else {
      return false
    }

    return characters.enumerated().allSatisfy { index, character in
      switch index {
      case 8, 15:
        true
      case 0..<8, 9..<15:
        character.isNumber
      case 16..<22:
        character.isNumber || ("a"..."z").contains(character)
      default:
        false
      }
    }
  }

  private static let idTimestampFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    return formatter
  }()

  static func makeRandomIDSuffix() -> String {
    let alphabet = Array("0123456789abcdefghijklmnopqrstuvwxyz")
    return String((0..<6).map { _ in alphabet[Int.random(in: alphabet.indices)] })
  }
}

private struct MemoryCardMetadata: Codable {
  var id: String
  var title: String
  var due: String?
  var stability: Double?
  var difficulty: Double?
  var lastSeen: String?
  var createdAt: String

  private enum CodingKeys: String, CodingKey {
    case id
    case title
    case due
    case stability
    case difficulty
    case lastSeen = "last_seen"
    case createdAt = "created_at"
  }

  init(card: MemoryCard, formatDate: (Date) -> String) {
    id = card.id
    title = card.title
    due = card.due.map(formatDate)
    stability = card.stability
    difficulty = card.difficulty
    lastSeen = card.lastSeen.map(formatDate)
    createdAt = formatDate(card.createdAt)
  }
}
