import Foundation
import Yams

enum MemoryCardMarkdownCodecError: Error, Equatable {
  case missingFrontMatter(URL)
}

enum MemoryCardMarkdownCodec {
  static func encode(_ card: MemoryCard) throws -> String {
    let metadata = MemoryCardMetadata(card: card)
    let yaml = try YAMLEncoder().encode(metadata)
    return [
      "---",
      yaml.trimmingCharacters(in: .newlines),
      "---",
      "",
      card.body,
    ].joined(separator: "\n")
  }

  static func decode(content: String, fileURL: URL, fallbackDate: Date) throws -> MemoryCard {
    guard content.hasPrefix("---\n") else {
      throw MemoryCardMarkdownCodecError.missingFrontMatter(fileURL)
    }

    let metadataStart = content.index(content.startIndex, offsetBy: 4)
    guard metadataStart < content.endIndex else {
      throw MemoryCardMarkdownCodecError.missingFrontMatter(fileURL)
    }

    let metadataSearchRange = metadataStart..<content.endIndex
    guard let endRange = content.range(of: "\n---\n", range: metadataSearchRange) else {
      throw MemoryCardMarkdownCodecError.missingFrontMatter(fileURL)
    }

    let metadataYAML = String(content[metadataStart..<endRange.lowerBound])
    let bodyStart = bodyStart(in: content, after: endRange)
    let body = String(content[bodyStart...])
    let metadata = try YAMLDecoder().decode(MemoryCardMetadata.self, from: metadataYAML)
    let createdAt = metadata.createdAt.flatMap(ISO8601Codec.parse) ?? fallbackDate

    return MemoryCard(
      id: metadata.id,
      body: body,
      directory: fileURL.deletingLastPathComponent().lastPathComponent,
      due: metadata.due.flatMap(ISO8601Codec.parse),
      stability: metadata.stability,
      difficulty: metadata.difficulty,
      lastSeen: metadata.lastSeen.flatMap(ISO8601Codec.parse),
      createdAt: createdAt,
      updatedAt: metadata.updatedAt.flatMap(ISO8601Codec.parse) ?? createdAt)
  }

  private static func bodyStart(
    in content: String,
    after frontMatterEndRange: Range<String.Index>
  ) -> String.Index {
    let bodyStart = frontMatterEndRange.upperBound
    guard bodyStart < content.endIndex, content[bodyStart] == "\n" else {
      return bodyStart
    }

    return content.index(after: bodyStart)
  }
}

private struct MemoryCardMetadata: Codable {
  var id: String
  var due: String?
  var stability: Double?
  var difficulty: Double?
  var lastSeen: String?
  var createdAt: String?
  var updatedAt: String?

  private enum CodingKeys: String, CodingKey {
    case id
    case due
    case stability
    case difficulty
    case lastSeen = "last_seen"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }

  init(card: MemoryCard) {
    id = card.id
    due = card.due.map(ISO8601Codec.format)
    stability = card.stability
    difficulty = card.difficulty
    lastSeen = card.lastSeen.map(ISO8601Codec.format)
    createdAt = ISO8601Codec.format(card.createdAt)
    updatedAt = ISO8601Codec.format(card.updatedAt)
  }
}
