import AppKit
import CoreText

/// Parses inline ruby (furigana) syntax `{base|reading}` and produces attributed
/// strings carrying `CTRubyAnnotation`.
///
/// Syntax (DenDenMarkdown-flavored):
/// - `{東京|とうきょう}` — group ruby: one reading over the whole base.
/// - `{東京|とう|きょう}` — mono ruby: one reading per base character.
/// - Readings may be separated by `|` or the full-width middle dot `・`.
/// - Mapping rule when there are multiple readings: the first N−1 readings each
///   take one base character; the last reading takes all remaining characters.
///   So `{小夜時雨|さ|よ|しぐれ}` → 小=さ, 夜=よ, 時雨=しぐれ.
///
/// Convention for bases that mix kanji and kana (e.g. 木漏れ日): write them as
/// **mono ruby** with one segment per character, annotating each kana with
/// itself — `{木漏れ日|こ|も|れ|び}`. A segment whose reading equals its base
/// character renders plain (kana need no reading and would otherwise sit higher
/// than their kanji neighbours). Group ruby over a mixed base
/// (`{木漏れ日|こもれび}`) is **not** laid out well by CoreText — the reading
/// clumps toward the center — and there is no unambiguous way to auto-split a
/// single reading back onto kanji vs kana, so that is left to the author.
enum RubyAnnotation {
  /// Matches `{base|reading(|reading)*}`. Group 1 = base, group 2 = the readings
  /// portion (including leading separators). Separators `|` and `・` are excluded
  /// from the character classes so they delimit segments. The pattern is a fixed
  /// literal, so compilation never fails in practice; `try?` keeps the type
  /// optional without a force-try.
  private static let pattern = try? NSRegularExpression(
    pattern: "\\{([^{}|・]+)((?:[|・][^{}|・]+)+)\\}")

  private static let separators = CharacterSet(charactersIn: "|・")

  /// Scans `text` for ruby syntax and returns an attributed string where matched
  /// spans carry `CTRubyAnnotation` and the rest uses `baseAttributes`. Returns
  /// `nil` when there is no ruby syntax, so callers can fall back to a plain
  /// string without allocating.
  static func attributedString(
    from text: String, baseAttributes: [NSAttributedString.Key: Any], baseFont: NSFont
  ) -> NSAttributedString? {
    let nsText = text as NSString
    let fullRange = NSRange(location: 0, length: nsText.length)
    guard let pattern else {
      return nil
    }
    let matches = pattern.matches(in: text, range: fullRange)
    guard !matches.isEmpty else {
      return nil
    }

    let output = NSMutableAttributedString()
    var cursor = 0
    for match in matches {
      if match.range.location > cursor {
        let plain = nsText.substring(
          with: NSRange(location: cursor, length: match.range.location - cursor))
        output.append(NSAttributedString(string: plain, attributes: baseAttributes))
      }

      let base = nsText.substring(with: match.range(at: 1))
      let readingsPart = nsText.substring(with: match.range(at: 2))
      let readings =
        readingsPart
        .components(separatedBy: separators)
        .filter { !$0.isEmpty }
      output.append(
        annotated(
          base: base, readings: readings, baseAttributes: baseAttributes, baseFont: baseFont))

      cursor = match.range.location + match.range.length
    }
    if cursor < nsText.length {
      let plain = nsText.substring(with: NSRange(location: cursor, length: nsText.length - cursor))
      output.append(NSAttributedString(string: plain, attributes: baseAttributes))
    }
    return output
  }

  /// Builds the annotated span for one `{base|…}` match.
  private static func annotated(
    base: String, readings: [String], baseAttributes: [NSAttributedString.Key: Any],
    baseFont: NSFont
  ) -> NSAttributedString {
    let characters = base.map(String.init)

    // Group ruby: single reading, or readings can't be distributed per character.
    if readings.count <= 1 || readings.count > characters.count {
      let reading = readings.joined()
      return span(base, reading: reading, baseAttributes: baseAttributes, baseFont: baseFont)
    }

    // Mono ruby: first N−1 readings take one character each, the last takes the rest.
    let result = NSMutableAttributedString()
    for (index, reading) in readings.enumerated() {
      let segment: String
      if index < readings.count - 1 {
        segment = characters[index]
      } else {
        segment = characters[index...].joined()
      }
      result.append(
        span(segment, reading: reading, baseAttributes: baseAttributes, baseFont: baseFont))
    }
    return result
  }

  /// One base span, with a ruby annotation above it unless the reading is
  /// identical to the base. A kana annotating itself (e.g. れ→れ in a per-char
  /// reading) carries no information and, when annotated, sits slightly higher
  /// than its kanji neighbours; rendering it plain keeps the row aligned.
  private static func span(
    _ base: String, reading: String, baseAttributes: [NSAttributedString.Key: Any], baseFont: NSFont
  ) -> NSAttributedString {
    guard base != reading else {
      return NSAttributedString(string: base, attributes: baseAttributes)
    }
    let annotation = CTRubyAnnotationCreateWithAttributes(
      .auto, .auto, .before, reading as CFString,
      [kCTFontAttributeName: NSFont.systemFont(ofSize: baseFont.pointSize * 0.5)] as CFDictionary)
    var attributes = baseAttributes
    attributes[kCTRubyAnnotationAttributeName as NSAttributedString.Key] = annotation
    return NSAttributedString(string: base, attributes: attributes)
  }
}
