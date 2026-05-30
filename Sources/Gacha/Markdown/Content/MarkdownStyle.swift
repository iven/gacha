import AppKit

/// Centralizes all visual constants and derived fonts/colors/paragraph styles
/// for rendered Markdown. Values are expressed as multiples of the base font
/// size so the whole document scales together.
struct MarkdownStyle {
  let appearance: MarkdownAppearance
  // Larger than the system font size to keep body text and its ruby annotations
  // legible.
  let baseFontSize = NSFont.systemFontSize * 1.15

  // Heading: font size and opacity step down by level (H1...H6).
  private static let headingFontScales: [CGFloat] = [2.17, 1.75, 1.25, 1.0, 1.0, 1.0]
  private static let headingAlphas: [CGFloat] = [1.0, 0.95, 0.85, 0.65, 0.65, 0.65]
  private static let headingTopSpacings: [CGFloat] = [1.2, 1.1, 1.0, 1.0, 1.0, 1.0]
  private static let headingBottomSpacings: [CGFloat] = [1.0, 0.55, 0.5, 0.5, 0.5, 0.5]

  private static let blockSpacing: CGFloat = 0.35
  private static let blockQuoteOuterSpacing: CGFloat = 0.85
  private static let blockQuoteVerticalPadding: CGFloat = 0.15
  private static let blockQuoteHeadIndent: CGFloat = 1.0
  private static let blockQuoteBarWidth: CGFloat = 3
  private static let lineSpacing: CGFloat = 2

  // Ruby annotations are drawn above the base text and TextKit reserves no room
  // for them, so ruby-bearing paragraphs need extra line height to avoid the
  // annotation clipping at the top or overlapping the line above.
  private static let rubyLineHeightMultiple: CGFloat = 1.6

  // MARK: Colors

  /// Body text is slightly dimmed so rendered Markdown sits softly against the
  /// notch background; bold runs use the full strength to stand out.
  private static let bodyTextAlpha: CGFloat = 0.82
  private static let strongTextAlpha: CGFloat = 0.95

  private var baseTextColor: NSColor {
    appearance == .dark ? .white : .black
  }

  var textColor: NSColor {
    baseTextColor.withAlphaComponent(Self.bodyTextAlpha)
  }

  var strongTextColor: NSColor {
    baseTextColor.withAlphaComponent(Self.strongTextAlpha)
  }

  var secondaryTextColor: NSColor {
    let alpha: CGFloat = appearance == .dark ? 0.62 : 0.56
    return baseTextColor.withAlphaComponent(alpha * Self.bodyTextAlpha)
  }

  // MARK: Inline styles

  func baseStyle(paragraphStyle: NSParagraphStyle? = nil) -> InlineStyle {
    InlineStyle(
      font: .systemFont(ofSize: baseFontSize),
      color: textColor,
      paragraphStyle: paragraphStyle ?? bodyParagraphStyle())
  }

  func headingStyle(level: Int) -> InlineStyle {
    let index = clampedHeadingIndex(level)
    let font = NSFont.boldSystemFont(ofSize: baseFontSize * Self.headingFontScales[index])
    let color = textColor.withAlphaComponent(Self.headingAlphas[index] * Self.bodyTextAlpha)
    return InlineStyle(font: font, color: color, paragraphStyle: bodyParagraphStyle())
  }

  func codeAttributes(paragraphStyle: NSParagraphStyle? = nil) -> [NSAttributedString.Key: Any] {
    [
      .font: NSFont.monospacedSystemFont(ofSize: baseFontSize, weight: .regular),
      .foregroundColor: NSColor.systemBrown.withAlphaComponent(Self.bodyTextAlpha),
      .paragraphStyle: paragraphStyle ?? bodyParagraphStyle(),
    ]
  }

  /// Color for link text, dimmed to match the rest of the rendered Markdown.
  var linkColor: NSColor {
    NSColor.linkColor.withAlphaComponent(Self.bodyTextAlpha)
  }

  // MARK: Paragraph styles

  func bodyParagraphStyle() -> NSMutableParagraphStyle {
    let style = NSMutableParagraphStyle()
    style.lineSpacing = Self.lineSpacing
    return style
  }

  /// Returns a copy of `base` with extra line height so ruby annotations have
  /// room above the text. Applied only to paragraphs that actually contain ruby.
  func applyingRubyLineHeight(to base: NSParagraphStyle) -> NSParagraphStyle {
    let style = (base.mutableCopy() as? NSMutableParagraphStyle) ?? bodyParagraphStyle()
    style.lineHeightMultiple = Self.rubyLineHeightMultiple
    return style
  }

  func blockQuoteParagraphStyle() -> NSMutableParagraphStyle {
    let style = bodyParagraphStyle()
    style.headIndent = baseFontSize * Self.blockQuoteHeadIndent
    style.firstLineHeadIndent = baseFontSize * Self.blockQuoteHeadIndent
    return style
  }

  func listParagraphStyle(lists: [NSTextList]) -> NSMutableParagraphStyle {
    // NSTextList draws and positions the markers itself; marker-to-text spacing
    // is fixed by the framework and not influenced by tab stops, so we only
    // attach the list hierarchy and keep the default spacing.
    let style = bodyParagraphStyle()
    style.textLists = lists
    return style
  }

  // MARK: Block quote decoration

  func blockQuoteDecoration() -> BlockQuoteDecoration {
    BlockQuoteDecoration(
      barColor: secondaryTextColor,
      barWidth: Self.blockQuoteBarWidth,
      verticalPadding: baseFontSize * Self.blockQuoteVerticalPadding)
  }

  // MARK: Margins (multiples of base font size, collapsed between blocks)

  func headingMargin(level: Int) -> BlockMargin {
    let index = clampedHeadingIndex(level)
    return BlockMargin(
      top: baseFontSize * Self.headingTopSpacings[index],
      bottom: baseFontSize * Self.headingBottomSpacings[index])
  }

  func blockQuoteMargin() -> BlockMargin {
    let spacing = baseFontSize * Self.blockQuoteOuterSpacing
    return BlockMargin(top: spacing, bottom: spacing)
  }

  func defaultBlockMargin() -> BlockMargin {
    let spacing = baseFontSize * Self.blockSpacing
    return BlockMargin(top: spacing, bottom: spacing)
  }

  private func clampedHeadingIndex(_ level: Int) -> Int {
    max(0, min(level - 1, Self.headingFontScales.count - 1))
  }
}

/// Top and bottom spacing requested by a block. Adjacent blocks collapse their
/// facing margins to the larger of the two (CSS-like margin collapsing).
struct BlockMargin {
  let top: CGFloat
  let bottom: CGFloat

  static let zero = BlockMargin(top: 0, bottom: 0)
}
