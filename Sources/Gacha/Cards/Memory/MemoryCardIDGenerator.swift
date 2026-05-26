import Foundation

enum MemoryCardIDGenerator {
  static func make(createdAt: Date, randomSuffix: () -> String) -> String {
    "\(idTimestampFormatter.string(from: createdAt))-\(randomSuffix())"
  }

  static func isValid(_ id: String) -> Bool {
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

  static func makeRandomSuffix() -> String {
    let alphabet = Array("0123456789abcdefghijklmnopqrstuvwxyz")
    return String((0..<6).map { _ in alphabet[Int.random(in: alphabet.indices)] })
  }

  private static let idTimestampFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    return formatter
  }()
}
