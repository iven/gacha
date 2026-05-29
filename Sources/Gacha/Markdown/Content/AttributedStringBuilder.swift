import AppKit
import Markdown

private let allowedLinkSchemes: Set<String> = ["http", "https", "mailto"]

extension NSTextList.MarkerFormat {
  /// Decimal markers with a trailing period (e.g. "1."), matching the
  /// conventional ordered-list appearance. The bare `.decimal` format omits it.
  static let orderedDecimal = NSTextList.MarkerFormat("{decimal}.")
}

/// Walks a swift-markdown `Document` and produces an `NSAttributedString` ready
/// for a TextKit 2 text view.
///
/// Block-level layout is expressed through paragraph styles (spacing, indents,
/// `NSTextList`, list tab stops) and a `.markdownBlockQuote` decoration
/// attribute consumed by the layout-fragment drawing code — never by inserting
/// layout-only glyphs into the text.
struct AttributedStringBuilder {
  private let style: MarkdownStyle

  init(appearance: MarkdownAppearance) {
    self.style = MarkdownStyle(appearance: appearance)
  }

  func build(_ markdown: String) -> NSAttributedString {
    let output = NSMutableAttributedString()
    appendBlocks(Document(parsing: markdown).children, to: output, lists: [])
    return output
  }

  // MARK: Block flow

  private func appendBlocks(
    _ blocks: MarkupChildren, to output: NSMutableAttributedString, lists: [NSTextList]
  ) {
    var previousMargin: BlockMargin?

    for block in blocks {
      let rendered = renderBlock(block, lists: lists)
      guard rendered.attributedString.length > 0 else {
        continue
      }

      if let previousMargin {
        let gap = max(previousMargin.bottom, rendered.margin.top)
        appendParagraphSeparator(to: output, spacing: gap)
      }

      output.append(rendered.attributedString)
      previousMargin = rendered.margin
    }
  }

  private func renderBlock(_ block: Markup, lists: [NSTextList]) -> RenderedBlock {
    switch block {
    case let heading as Heading:
      let body = renderInlineChildren(of: heading, style: style.headingStyle(level: heading.level))
      return RenderedBlock(
        attributedString: rubyAdjusted(body), margin: style.headingMargin(level: heading.level))

    case let paragraph as Paragraph:
      let body = renderInlineChildren(of: paragraph, style: style.baseStyle())
      return RenderedBlock(
        attributedString: rubyAdjusted(body), margin: style.defaultBlockMargin())

    case let codeBlock as CodeBlock:
      let body = NSAttributedString(
        string: trimTrailingNewline(codeBlock.code), attributes: style.codeAttributes())
      return RenderedBlock(attributedString: body, margin: style.defaultBlockMargin())

    case let blockQuote as BlockQuote:
      return renderBlockQuote(blockQuote, lists: lists)

    case let unorderedList as UnorderedList:
      return renderList(Array(unorderedList.listItems), marker: .disc, lists: lists)

    case let orderedList as OrderedList:
      return renderList(Array(orderedList.listItems), marker: .orderedDecimal, lists: lists)

    default:
      let output = NSMutableAttributedString()
      appendBlocks(block.children, to: output, lists: lists)
      return RenderedBlock(attributedString: output, margin: .zero)
    }
  }

  private func renderBlockQuote(_ blockQuote: BlockQuote, lists: [NSTextList]) -> RenderedBlock {
    let inner = NSMutableAttributedString()
    appendBlocks(blockQuote.children, to: inner, lists: lists)
    guard inner.length > 0 else {
      return RenderedBlock(attributedString: inner, margin: .zero)
    }

    let range = NSRange(location: 0, length: inner.length)
    inner.addAttribute(.foregroundColor, value: style.secondaryTextColor, range: range)
    inner.addAttribute(.markdownBlockQuote, value: style.blockQuoteDecoration(), range: range)
    applyHeadIndent(style.blockQuoteParagraphStyle(), to: inner)
    return RenderedBlock(attributedString: inner, margin: style.blockQuoteMargin())
  }

  /// Renders list items, letting `NSTextList` draw and number the markers. The
  /// `lists` stack grows by one level per nesting depth so paragraph styles
  /// carry the full marker hierarchy.
  private func renderList(
    _ items: [ListItem], marker: NSTextList.MarkerFormat, lists: [NSTextList]
  ) -> RenderedBlock {
    let list = NSTextList(markerFormat: marker, options: 0)
    let nestedLists = lists + [list]
    let output = NSMutableAttributedString()

    for (index, item) in items.enumerated() {
      if index > 0 {
        output.append(string: "\n")
      }
      output.append(renderListItem(item, lists: nestedLists).attributedString)
    }
    return RenderedBlock(attributedString: output, margin: style.defaultBlockMargin())
  }

  private func renderListItem(_ item: ListItem, lists: [NSTextList]) -> RenderedBlock {
    let output = NSMutableAttributedString()
    var previousMargin: BlockMargin?

    for child in item.children {
      let rendered: RenderedBlock
      if child is UnorderedList || child is OrderedList {
        rendered = renderBlock(child, lists: lists)
      } else if let paragraph = child as? Paragraph {
        let body = renderInlineChildren(
          of: paragraph,
          style: style.baseStyle(paragraphStyle: style.listParagraphStyle(lists: lists)))
        rendered = RenderedBlock(attributedString: body, margin: style.defaultBlockMargin())
      } else {
        rendered = renderBlock(child, lists: lists)
      }

      guard rendered.attributedString.length > 0 else {
        continue
      }
      if previousMargin != nil {
        output.append(string: "\n")
      }
      output.append(rendered.attributedString)
      previousMargin = rendered.margin
    }
    return RenderedBlock(attributedString: output, margin: style.defaultBlockMargin())
  }

  // MARK: Inline flow

  private func renderInlineChildren(of markup: Markup, style inlineStyle: InlineStyle)
    -> NSAttributedString
  {
    let output = NSMutableAttributedString()
    for child in markup.children {
      output.append(renderInline(child, style: inlineStyle))
    }
    return output
  }

  /// Renders a plain text run, applying ruby annotations if it contains `{…|…}`.
  private func renderText(_ string: String, style inlineStyle: InlineStyle) -> NSAttributedString {
    RubyAnnotation.attributedString(
      from: string, baseAttributes: inlineStyle.attributes, baseFont: inlineStyle.font)
      ?? NSAttributedString(string: string, attributes: inlineStyle.attributes)
  }

  private func renderInline(_ markup: Markup, style inlineStyle: InlineStyle) -> NSAttributedString
  {
    switch markup {
    case let text as Text:
      return renderText(text.string, style: inlineStyle)

    case let inlineCode as InlineCode:
      return NSAttributedString(
        string: inlineCode.code,
        attributes: style.codeAttributes(paragraphStyle: inlineStyle.paragraphStyle))

    case is SoftBreak:
      return NSAttributedString(string: " ", attributes: inlineStyle.attributes)

    case is LineBreak:
      return NSAttributedString(string: "\n", attributes: inlineStyle.attributes)

    case let strong as Strong:
      return renderInlineChildren(
        of: strong, style: inlineStyle.with { $0.font = applyTrait(.bold, to: $0.font) })

    case let emphasis as Emphasis:
      return renderInlineChildren(
        of: emphasis, style: inlineStyle.with { $0.font = applyTrait(.italic, to: $0.font) })

    case let strikethrough as Strikethrough:
      return renderInlineChildren(
        of: strikethrough, style: inlineStyle.with { $0.strikethrough = true })

    case let link as Link:
      return renderLink(link, style: inlineStyle)

    case let image as Image:
      let altText = renderInlineChildren(of: image, style: inlineStyle).string
      return NSAttributedString(
        string: altText.isEmpty ? "[image]" : altText, attributes: inlineStyle.attributes)

    default:
      return renderInlineChildren(of: markup, style: inlineStyle)
    }
  }

  private func renderLink(_ link: Link, style inlineStyle: InlineStyle) -> NSAttributedString {
    let safeURL = link.destination.flatMap(sanitizedLinkURL(from:))
    let linkStyle = inlineStyle.with {
      if safeURL != nil {
        $0.color = .linkColor
        $0.underline = true
      }
    }
    let output = NSMutableAttributedString(
      attributedString: renderInlineChildren(of: link, style: linkStyle))
    if let safeURL {
      output.addAttribute(
        .link, value: safeURL, range: NSRange(location: 0, length: output.length))
    }
    return output
  }

  private func sanitizedLinkURL(from destination: String) -> URL? {
    guard let url = URL(string: destination), let scheme = url.scheme?.lowercased() else {
      return nil
    }
    return allowedLinkSchemes.contains(scheme) ? url : nil
  }

  // MARK: Helpers

  /// Separates two blocks with a single newline whose paragraph carries the
  /// collapsed spacing. The newline is the necessary paragraph delimiter; the
  /// gap itself lives in `paragraphSpacing`, not in extra blank lines.
  private func appendParagraphSeparator(to output: NSMutableAttributedString, spacing: CGFloat) {
    guard output.length > 0 else {
      return
    }
    let paragraphRange = (output.string as NSString).paragraphRange(
      for: NSRange(location: output.length - 1, length: 0))
    let attributes = output.attributes(at: output.length - 1, effectiveRange: nil)
    let paragraphStyle =
      (attributes[.paragraphStyle] as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle
      ?? style.bodyParagraphStyle()
    paragraphStyle.paragraphSpacing = spacing
    output.addAttribute(.paragraphStyle, value: paragraphStyle, range: paragraphRange)

    var separatorAttributes = attributes
    separatorAttributes[.paragraphStyle] = paragraphStyle
    output.append(string: "\n", attributes: separatorAttributes)
  }

  /// If the rendered block contains any ruby annotation, raises its paragraphs'
  /// line height so the annotation has room above the text. Plain blocks are
  /// returned unchanged so they stay compact.
  private func rubyAdjusted(_ attributed: NSAttributedString) -> NSAttributedString {
    let fullRange = NSRange(location: 0, length: attributed.length)
    let rubyKey = kCTRubyAnnotationAttributeName as NSAttributedString.Key
    var hasRuby = false
    attributed.enumerateAttribute(rubyKey, in: fullRange) { value, _, stop in
      if value != nil {
        hasRuby = true
        stop.pointee = true
      }
    }
    guard hasRuby else {
      return attributed
    }

    let mutable = NSMutableAttributedString(attributedString: attributed)
    mutable.enumerateAttribute(.paragraphStyle, in: fullRange) { value, range, _ in
      let base = (value as? NSParagraphStyle) ?? style.bodyParagraphStyle()
      mutable.addAttribute(
        .paragraphStyle, value: style.applyingRubyLineHeight(to: base), range: range)
    }
    return mutable
  }

  private func applyHeadIndent(
    _ indentStyle: NSMutableParagraphStyle, to target: NSMutableAttributedString
  ) {
    let range = NSRange(location: 0, length: target.length)
    target.enumerateAttribute(.paragraphStyle, in: range) { value, subRange, _ in
      // Add the quote indent on top of any inner list/spacing styling. Each run
      // gets its own copy so styles are never shared between ranges.
      let base =
        (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle
        ?? style.bodyParagraphStyle()
      base.headIndent += indentStyle.headIndent
      base.firstLineHeadIndent += indentStyle.firstLineHeadIndent
      target.addAttribute(.paragraphStyle, value: base, range: subRange)
    }
  }

  private func applyTrait(_ trait: NSFontDescriptor.SymbolicTraits, to font: NSFont) -> NSFont {
    var traits = font.fontDescriptor.symbolicTraits
    traits.insert(trait)
    let descriptor = font.fontDescriptor.withSymbolicTraits(traits)
    return NSFont(descriptor: descriptor, size: font.pointSize) ?? font
  }

  private func trimTrailingNewline(_ string: String) -> String {
    var result = string
    while result.hasSuffix("\n") {
      result.removeLast()
    }
    return result
  }
}

private struct RenderedBlock {
  let attributedString: NSAttributedString
  let margin: BlockMargin
}
