import AppKit
import SwiftUI

/// Bridges a TextKit 2 `NSTextView` into SwiftUI. The text view is created with
/// the designated text-container initializer so it stays on TextKit 2; the code
/// never touches `.layoutManager`, which would force an irreversible fallback to
/// TextKit 1 and break ruby annotations added later.
///
/// The text view is made non-resizable so SwiftUI fully owns its frame, and the
/// content height is reported through `sizeThatFits`. A self-resizing
/// `NSTextView` inside a SwiftUI `ScrollView` fights SwiftUI's layout and
/// collapses to a residual single-line height, clipping all text.
struct MarkdownTextView: NSViewRepresentable {
  let attributedText: NSAttributedString

  func makeCoordinator() -> MarkdownLayoutDelegate {
    MarkdownLayoutDelegate()
  }

  func makeNSView(context: Context) -> MeasuringTextView {
    let textLayoutManager = NSTextLayoutManager()
    textLayoutManager.delegate = context.coordinator

    let textContainer = NSTextContainer(size: .zero)
    textContainer.lineFragmentPadding = 0
    textContainer.widthTracksTextView = true
    textLayoutManager.textContainer = textContainer

    let contentStorage = NSTextContentStorage()
    contentStorage.addTextLayoutManager(textLayoutManager)

    let textView = MeasuringTextView(frame: .zero, textContainer: textContainer)
    textView.isEditable = false
    textView.isSelectable = true
    textView.drawsBackground = false
    textView.backgroundColor = .clear
    textView.textContainerInset = .zero
    // Let SwiftUI fully drive the frame via sizeThatFits. A self-resizing
    // NSTextView fights SwiftUI's layout and collapses to a residual height.
    textView.isHorizontallyResizable = false
    textView.isVerticallyResizable = false
    textView.autoresizingMask = [.width]
    textView.assertStaysOnTextKit2()
    return textView
  }

  func updateNSView(_ textView: MeasuringTextView, context: Context) {
    guard
      let contentStorage = textView.textLayoutManager?.textContentManager as? NSTextContentStorage
    else {
      return
    }
    if contentStorage.textStorage?.isEqual(to: attributedText) != true {
      contentStorage.textStorage?.setAttributedString(attributedText)
    }
  }

  func sizeThatFits(
    _ proposal: ProposedViewSize, nsView textView: MeasuringTextView, context: Context
  ) -> CGSize? {
    guard let width = proposal.width, width > 0, width.isFinite else {
      return nil
    }
    let height = textView.contentHeight(forWidth: width)
    return CGSize(width: width, height: height)
  }
}

/// An `NSTextView` that measures its laid-out height via the TextKit 2
/// `usageBoundsForTextContainer`, without ever touching a glyph-based layout
/// manager.
final class MeasuringTextView: NSTextView {
  // Removed from the (nonisolated) deinit, so it must be reachable without actor
  // isolation; the token itself is only mutated on the main actor.
  private nonisolated(unsafe) var fallbackObserver: NSObjectProtocol?

  deinit {
    if let fallbackObserver {
      NotificationCenter.default.removeObserver(fallbackObserver)
    }
  }

  /// Lays out the content at the given width and returns its full height.
  func contentHeight(forWidth width: CGFloat) -> CGFloat {
    guard let textLayoutManager, let textContainer else {
      return 0
    }
    // Width is fixed by SwiftUI; height is unbounded so the content lays out
    // fully and we can read its true height. (A height of 0 would be treated as
    // a zero-height container and clip everything.)
    textContainer.size = NSSize(width: width, height: .greatestFiniteMagnitude)
    textLayoutManager.ensureLayout(for: textLayoutManager.documentRange)
    return ceil(
      textLayoutManager.usageBoundsForTextContainer.height + textContainerInset.height * 2)
  }

  /// Verifies the view is using TextKit 2 and warns if it ever falls back.
  func assertStaysOnTextKit2() {
    assert(textLayoutManager != nil, "MarkdownTextView must stay on TextKit 2")
    fallbackObserver = NotificationCenter.default.addObserver(
      forName: NSTextView.willSwitchToNSLayoutManagerNotification,
      object: self, queue: .main
    ) { _ in
      assertionFailure("MarkdownTextView fell back to TextKit 1 — ruby annotations will break")
    }
  }
}
