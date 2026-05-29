import AppKit

/// A layout fragment that draws a vertical bar at the body's left margin before
/// drawing the (indented) block-quote text. Replaces TextKit 1's view-level
/// glyph-rect drawing.
///
/// The quote paragraph is indented (`headIndent`) so its text shifts right; the
/// bar is drawn back at the container's leading edge (x = 0), aligning its left
/// edge with the surrounding body text. Because that is left of this fragment's
/// own frame, `renderingSurfaceBounds` is widened so the bar isn't clipped.
final class BlockQuoteLayoutFragment: NSTextLayoutFragment {
  let decoration: BlockQuoteDecoration

  init(textElement: NSTextElement, range: NSTextRange?, decoration: BlockQuoteDecoration) {
    self.decoration = decoration
    super.init(textElement: textElement, range: range)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  /// Distance from this fragment's local origin back to the container's leading
  /// edge (the body's left margin), where the bar is drawn.
  private var leadingEdgeOffset: CGFloat {
    layoutFragmentFrame.minX
  }

  override var renderingSurfaceBounds: CGRect {
    // Extend the surface leftward to include the bar, which sits left of the
    // fragment frame at the container's leading edge.
    super.renderingSurfaceBounds.union(
      CGRect(
        x: -leadingEdgeOffset, y: 0, width: decoration.barWidth, height: layoutFragmentFrame.height)
    )
  }

  override func draw(at point: CGPoint, in context: CGContext) {
    // Union the text lines' typographic bounds (relative to the fragment frame
    // vertically) so the bar spans exactly the text rows, excluding the
    // paragraph spacing baked into layoutFragmentFrame.height.
    var textRect: CGRect?
    for line in textLineFragments {
      textRect = textRect.map { $0.union(line.typographicBounds) } ?? line.typographicBounds
    }

    if let textRect {
      let barRect = CGRect(
        x: point.x - leadingEdgeOffset,
        y: point.y + textRect.minY - decoration.verticalPadding,
        width: decoration.barWidth,
        height: textRect.height + decoration.verticalPadding * 2)

      context.saveGState()
      context.setFillColor(decoration.barColor.cgColor)
      context.fill(barRect)
      context.restoreGState()
    }

    super.draw(at: point, in: context)
  }
}
