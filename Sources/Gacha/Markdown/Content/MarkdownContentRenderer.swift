import CryptoKit
import Foundation

/// Content-layer entry point: turns Markdown source into a cached
/// `NSAttributedString` for a given appearance.
struct MarkdownContentRenderer: Sendable {
  private static let cache = RenderedMarkdownCache(limit: 64)

  let appearance: MarkdownAppearance

  func render(markdown: String) -> NSAttributedString {
    let key = cacheKey(for: markdown)
    if let cached = Self.cache.value(forKey: key) {
      return cached
    }

    let attributedString = AttributedStringBuilder(appearance: appearance).build(markdown)
    Self.cache.insert(attributedString, forKey: key)
    return attributedString
  }

  private func cacheKey(for markdown: String) -> String {
    let digest = SHA256.hash(data: Data(markdown.utf8))
    let hex = digest.map { String(format: "%02x", $0) }.joined()
    return "\(appearance.rawValue):\(hex)"
  }
}
