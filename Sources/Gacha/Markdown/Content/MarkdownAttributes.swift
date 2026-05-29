import AppKit

/// Custom attributed-string keys used to carry block-level rendering hints from
/// the content builder to the layout-fragment drawing code.
enum MarkdownAttribute {
  private static let prefix = "com.iven.gacha.markdown."

  /// Marks characters belonging to a block quote. Value is a `BlockQuoteDecoration`.
  static let blockQuote = NSAttributedString.Key(prefix + "blockQuote")
}

extension NSAttributedString.Key {
  static let markdownBlockQuote = MarkdownAttribute.blockQuote
}

/// Drawing parameters for the block quote bar, attached via `.markdownBlockQuote`.
/// `Hashable` because it is stored as an attributed-string attribute value, which
/// AppKit hashes internally.
struct BlockQuoteDecoration: Hashable {
  let barColor: NSColor
  let barWidth: CGFloat
  let verticalPadding: CGFloat
}
