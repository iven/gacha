import AppKit
import SwiftUI

/// SwiftUI wrapper around an `NSTextView` that reuses `MarkdownSyntaxHighlighter`
/// for live syntax highlighting. macOS 26's native `TextEditor(AttributedString:)`
/// is intentionally not used yet, so the highlighter stays untouched while the
/// surrounding layout moves to SwiftUI.
struct MarkdownSourceEditor: NSViewRepresentable {
  @Binding var text: String

  func makeCoordinator() -> Coordinator {
    Coordinator(text: $text)
  }

  func makeNSView(context: Context) -> NSScrollView {
    let scrollView = NSTextView.scrollableTextView()
    guard let textView = scrollView.documentView as? NSTextView else {
      return scrollView
    }

    scrollView.drawsBackground = true
    scrollView.backgroundColor = .textBackgroundColor

    textView.font = .preferredFont(forTextStyle: .body)
    textView.backgroundColor = .textBackgroundColor
    textView.isSelectable = true
    textView.isEditable = true
    textView.allowsUndo = true
    textView.textContainerInset = NSSize(width: 20, height: 20)
    textView.delegate = context.coordinator
    textView.string = text
    context.coordinator.textView = textView
    context.coordinator.applyHighlight()
    return scrollView
  }

  func updateNSView(_ scrollView: NSScrollView, context: Context) {
    guard let textView = scrollView.documentView as? NSTextView else {
      return
    }

    context.coordinator.text = $text
    if textView.string != text {
      context.coordinator.isApplyingText = true
      textView.string = text
      context.coordinator.applyHighlight()
      context.coordinator.isApplyingText = false
    }
  }

  @MainActor
  final class Coordinator: NSObject, NSTextViewDelegate {
    var text: Binding<String>
    weak var textView: NSTextView?
    var isApplyingText = false
    private let highlighter = MarkdownSyntaxHighlighter()

    init(text: Binding<String>) {
      self.text = text
    }

    func textDidChange(_ notification: Notification) {
      guard !isApplyingText, let textView else {
        return
      }

      applyHighlight()
      text.wrappedValue = textView.string
    }

    func applyHighlight() {
      guard let textView else {
        return
      }

      highlighter.apply(to: textView)
    }
  }
}
