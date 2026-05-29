import SwiftUI

/// Public entry point: renders Markdown text into a TextKit 2-backed view.
struct MarkdownRenderer: View {
  let text: String

  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    MarkdownTextView(attributedText: attributedText)
      .padding(.vertical, 6)
      .opacity(0.82)
      .onHover { hovering in
        if hovering {
          NSCursor.iBeam.push()
        } else {
          NSCursor.pop()
        }
      }
  }

  private var attributedText: NSAttributedString {
    MarkdownContentRenderer(appearance: colorScheme == .dark ? .dark : .light)
      .render(markdown: text)
  }
}
