import AppKit
import Testing

@testable import Gacha

@Test func contentRendererCollapsesAdjacentBlockMargins() throws {
  let rendered = MarkdownContentRenderer(appearance: .light).render(markdown: "# Title\nBody")

  let separatorIndex = (rendered.string as NSString).range(of: "\n").location
  let paragraphStyle = try #require(
    rendered.attribute(.paragraphStyle, at: separatorIndex, effectiveRange: nil)
      as? NSParagraphStyle)

  #expect(paragraphStyle.paragraphSpacing == NSFont.systemFontSize)
}

@Test func contentRendererMarksBlockQuoteWithDecorationAndIndent() throws {
  let rendered = MarkdownContentRenderer(appearance: .light).render(
    markdown: """
      Before
      > Quote
      After
      """)

  let quoteRange = (rendered.string as NSString).range(of: "Quote")
  let paragraphStyle = try #require(
    rendered.attribute(.paragraphStyle, at: quoteRange.location, effectiveRange: nil)
      as? NSParagraphStyle)

  #expect(paragraphStyle.firstLineHeadIndent == NSFont.systemFontSize)
  #expect(paragraphStyle.headIndent == NSFont.systemFontSize)

  let decoration = try #require(
    rendered.attribute(.markdownBlockQuote, at: quoteRange.location, effectiveRange: nil)
      as? BlockQuoteDecoration)
  #expect(decoration.verticalPadding == NSFont.systemFontSize * 0.15)
  #expect(decoration.barWidth == 3)
}

@Test func contentRendererUsesTextListsForUnorderedBullets() throws {
  let rendered = MarkdownContentRenderer(appearance: .light).render(markdown: "- First\n- Second")

  // No manual marker text is inserted; NSTextList draws the bullets.
  #expect(rendered.string == "First\nSecond")

  let paragraphStyle = try #require(
    rendered.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)
  #expect(paragraphStyle.textLists.count == 1)
}

@Test func contentRendererNestsTextListsByDepth() throws {
  let rendered = MarkdownContentRenderer(appearance: .light).render(
    markdown: """
      - Parent
        - Child
      """)

  let childRange = (rendered.string as NSString).range(of: "Child")
  let childStyle = try #require(
    rendered.attribute(.paragraphStyle, at: childRange.location, effectiveRange: nil)
      as? NSParagraphStyle)

  // Nested item carries both the parent and child lists.
  #expect(childStyle.textLists.count == 2)
}

@Test func contentRendererUsesPeriodedOrderedMarkers() throws {
  let rendered = MarkdownContentRenderer(appearance: .light).render(markdown: "1. one\n2. two")

  let paragraphStyle = try #require(
    rendered.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)
  let list = try #require(paragraphStyle.textLists.first)
  #expect(list.marker(forItemNumber: 1) == "1.")
  #expect(list.marker(forItemNumber: 2) == "2.")
}

@Test func contentRendererPreservesSafeLinkURLs() throws {
  let rendered = MarkdownContentRenderer(appearance: .light).render(
    markdown: "[link](https://example.com)")

  let textRange = (rendered.string as NSString).range(of: "link")
  let url = try #require(
    rendered.attribute(.link, at: textRange.location, effectiveRange: nil) as? URL)
  #expect(url.absoluteString == "https://example.com")

  let underlineStyle =
    rendered.attribute(.underlineStyle, at: textRange.location, effectiveRange: nil) as? Int
  #expect(underlineStyle == NSUnderlineStyle.single.rawValue)

  let color = try #require(
    rendered.attribute(.foregroundColor, at: textRange.location, effectiveRange: nil) as? NSColor)
  #expect(color == .linkColor)
}

@Test func contentRendererStripsUnsafeLinkSchemes() throws {
  let rendered = MarkdownContentRenderer(appearance: .light).render(
    markdown: "[bad](javascript:alert(1)) plus [file](file:///etc/passwd)")

  let badRange = (rendered.string as NSString).range(of: "bad")
  #expect(rendered.attribute(.link, at: badRange.location, effectiveRange: nil) == nil)

  let fileRange = (rendered.string as NSString).range(of: "file")
  #expect(rendered.attribute(.link, at: fileRange.location, effectiveRange: nil) == nil)
}

@Test func contentRendererAppliesInlineEmphasisAttributes() throws {
  let rendered = MarkdownContentRenderer(appearance: .light).render(
    markdown: "**bold** _it_ ~~gone~~ `code`")

  let boldRange = (rendered.string as NSString).range(of: "bold")
  let boldFont = try #require(
    rendered.attribute(.font, at: boldRange.location, effectiveRange: nil) as? NSFont)
  #expect(boldFont.fontDescriptor.symbolicTraits.contains(.bold))

  let italicRange = (rendered.string as NSString).range(of: "it")
  let italicFont = try #require(
    rendered.attribute(.font, at: italicRange.location, effectiveRange: nil) as? NSFont)
  #expect(italicFont.fontDescriptor.symbolicTraits.contains(.italic))

  let strikeRange = (rendered.string as NSString).range(of: "gone")
  let strikeStyle =
    rendered.attribute(.strikethroughStyle, at: strikeRange.location, effectiveRange: nil) as? Int
  #expect(strikeStyle == NSUnderlineStyle.single.rawValue)

  let codeRange = (rendered.string as NSString).range(of: "code")
  let codeFont = try #require(
    rendered.attribute(.font, at: codeRange.location, effectiveRange: nil) as? NSFont)
  #expect(codeFont.fontName.lowercased().contains("mono"))
}

@Test func contentRendererCachingReturnsEqualOutput() throws {
  let renderer = MarkdownContentRenderer(appearance: .light)
  let first = renderer.render(markdown: "# Cached\nBody")
  let second = renderer.render(markdown: "# Cached\nBody")

  #expect(first.isEqual(to: second))
}
