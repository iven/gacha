import AppKit
import Markdown

@MainActor
struct MarkdownSyntaxHighlighter {
  let baseFontSize: CGFloat

  init(baseFontSize: CGFloat = NSFont.systemFontSize) {
    self.baseFontSize = baseFontSize
  }

  func apply(to textView: NSTextView) {
    guard let textStorage = textView.textStorage else {
      return
    }

    let text = textStorage.string
    let nsText = text as NSString
    let fullRange = NSRange(location: 0, length: nsText.length)
    textStorage.beginEditing()
    textStorage.setAttributes(
      [.font: NSFont.systemFont(ofSize: baseFontSize), .foregroundColor: NSColor.labelColor],
      range: fullRange)

    let context = HighlightContext(
      textStorage: textStorage,
      lines: makeLines(text: nsText),
      utf16Length: fullRange.length,
      baseFontSize: baseFontSize)
    walk(markup: Document(parsing: text), context: context)
    textStorage.endEditing()
  }

  private func walk(markup: Markup, context: HighlightContext) {
    apply(markup: markup, context: context)
    for child in markup.children {
      walk(markup: child, context: context)
    }
  }

  private func apply(markup: Markup, context: HighlightContext) {
    guard let range = nsRange(for: markup, context: context) else {
      return
    }

    switch markup {
    case let heading as Heading:
      let size = headingFontSize(level: heading.level)
      context.textStorage.addAttribute(
        .font, value: NSFont.boldSystemFont(ofSize: size), range: range)
      context.textStorage.addAttribute(
        .foregroundColor, value: headingColor(level: heading.level), range: range)
    case is Strong:
      addTrait(.bold, range: range, context: context)
    case is Emphasis:
      addTrait(.italic, range: range, context: context)
    case is InlineCode, is CodeBlock:
      let monospaced = NSFont.monospacedSystemFont(
        ofSize: context.baseFontSize, weight: .regular)
      context.textStorage.addAttribute(.font, value: monospaced, range: range)
      context.textStorage.addAttribute(
        .foregroundColor, value: NSColor.systemBrown, range: range)
    case is Link:
      context.textStorage.addAttribute(
        .foregroundColor, value: NSColor.linkColor, range: range)
      context.textStorage.addAttribute(
        .underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
    case is BlockQuote:
      context.textStorage.addAttribute(
        .foregroundColor, value: NSColor.secondaryLabelColor, range: range)
    default:
      break
    }
  }

  private func addTrait(
    _ trait: NSFontDescriptor.SymbolicTraits, range: NSRange,
    context: HighlightContext
  ) {
    context.textStorage.enumerateAttribute(.font, in: range, options: []) { value, subrange, _ in
      let currentFont = (value as? NSFont) ?? NSFont.systemFont(ofSize: context.baseFontSize)
      var traits = currentFont.fontDescriptor.symbolicTraits
      traits.insert(trait)
      let descriptor = currentFont.fontDescriptor.withSymbolicTraits(traits)
      let traited = NSFont(descriptor: descriptor, size: currentFont.pointSize) ?? currentFont
      context.textStorage.addAttribute(.font, value: traited, range: subrange)
    }
  }

  private static let headingAlphas: [CGFloat] = [1.0, 0.9, 0.75, 0.5, 0.5, 0.5]
  private static let headingFontScales: [CGFloat] = [2.5, 1.75, 1.25, 1.0, 1.0, 1.0]

  private func headingColor(level: Int) -> NSColor {
    let alpha = Self.headingAlphas[max(0, min(level - 1, Self.headingAlphas.count - 1))]
    return NSColor(name: nil) { appearance in
      let base =
        appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
        ? NSColor.white : NSColor.black
      return base.withAlphaComponent(alpha)
    }
  }

  private func headingFontSize(level: Int) -> CGFloat {
    let scale = Self.headingFontScales[max(0, min(level - 1, Self.headingFontScales.count - 1))]
    return baseFontSize * scale
  }

  private func nsRange(for markup: Markup, context: HighlightContext) -> NSRange? {
    guard let sourceRange = markup.range,
      let start = utf16Offset(
        line: sourceRange.lowerBound.line,
        column: sourceRange.lowerBound.column,
        context: context),
      let end = utf16Offset(
        line: sourceRange.upperBound.line,
        column: sourceRange.upperBound.column,
        context: context),
      end >= start
    else {
      return nil
    }

    let clampedEnd = min(end, context.utf16Length)
    let clampedStart = min(start, clampedEnd)
    return NSRange(location: clampedStart, length: clampedEnd - clampedStart)
  }

  private func utf16Offset(line: Int, column: Int, context: HighlightContext) -> Int? {
    let lineIndex = line - 1
    guard lineIndex >= 0, lineIndex < context.lines.count else {
      return nil
    }

    let info = context.lines[lineIndex]
    let utf8 = info.text.utf8
    let byteColumn = min(max(0, column - 1), utf8.count)
    let index = utf8.index(utf8.startIndex, offsetBy: byteColumn)
    return info.utf16Start + index.utf16Offset(in: info.text)
  }

  private func makeLines(text: NSString) -> [LineInfo] {
    var lines: [LineInfo] = []
    var lineStart = 0
    var index = 0
    while index < text.length {
      let character = text.character(at: index)
      index += 1
      if character == 0x0A {
        lines.append(makeLineInfo(start: lineStart, end: index, in: text))
        lineStart = index
      }
    }
    lines.append(makeLineInfo(start: lineStart, end: text.length, in: text))
    return lines
  }

  private func makeLineInfo(start: Int, end: Int, in text: NSString) -> LineInfo {
    let lineString = text.substring(with: NSRange(location: start, length: end - start))
    return LineInfo(utf16Start: start, text: lineString)
  }
}

private struct HighlightContext {
  let textStorage: NSTextStorage
  let lines: [LineInfo]
  let utf16Length: Int
  let baseFontSize: CGFloat
}

private struct LineInfo {
  let utf16Start: Int
  let text: String
}
