import Foundation

enum ISO8601Codec {
  static func format(_ date: Date) -> String {
    formatter(includingFractionalSeconds: true).string(from: date)
  }

  static func parse(_ value: String) -> Date? {
    formatter(includingFractionalSeconds: true).date(from: value)
      ?? formatter(includingFractionalSeconds: false).date(from: value)
  }

  private static func formatter(includingFractionalSeconds: Bool) -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions =
      includingFractionalSeconds
      ? [.withInternetDateTime, .withFractionalSeconds]
      : [.withInternetDateTime]
    return formatter
  }
}
