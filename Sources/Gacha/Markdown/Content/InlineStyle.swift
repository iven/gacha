import AppKit

/// A mutable value type describing inline text styling while walking the AST.
struct InlineStyle {
  var font: NSFont
  var color: NSColor
  var paragraphStyle: NSParagraphStyle
  var strikethrough = false
  var underline = false

  var attributes: [NSAttributedString.Key: Any] {
    var attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: color,
      .paragraphStyle: paragraphStyle,
    ]

    if strikethrough {
      attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
    }
    if underline {
      attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
    }
    return attributes
  }

  func with(_ transform: (inout InlineStyle) -> Void) -> InlineStyle {
    var copy = self
    transform(&copy)
    return copy
  }
}
