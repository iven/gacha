import AppKit

/// Returns a `BlockQuoteLayoutFragment` for elements whose first character
/// carries the `.markdownBlockQuote` decoration, and the default fragment
/// otherwise.
final class MarkdownLayoutDelegate: NSObject, NSTextLayoutManagerDelegate {
  func textLayoutManager(
    _ textLayoutManager: NSTextLayoutManager,
    textLayoutFragmentFor location: NSTextLocation,
    in textElement: NSTextElement
  ) -> NSTextLayoutFragment {
    let range = textElement.elementRange
    if let decoration = decoration(at: location, in: textLayoutManager) {
      return BlockQuoteLayoutFragment(
        textElement: textElement, range: range, decoration: decoration)
    }
    return NSTextLayoutFragment(textElement: textElement, range: range)
  }

  private func decoration(
    at location: NSTextLocation, in textLayoutManager: NSTextLayoutManager
  ) -> BlockQuoteDecoration? {
    guard
      let contentStorage = textLayoutManager.textContentManager as? NSTextContentStorage,
      let textStorage = contentStorage.textStorage
    else {
      return nil
    }

    let offset = contentStorage.offset(
      from: contentStorage.documentRange.location, to: location)
    guard offset >= 0, offset < textStorage.length else {
      return nil
    }
    return textStorage.attribute(.markdownBlockQuote, at: offset, effectiveRange: nil)
      as? BlockQuoteDecoration
  }
}
