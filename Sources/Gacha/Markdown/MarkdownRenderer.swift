import AppKit
import SwiftUI
import Textual

struct MarkdownRenderer: View {
  let text: String

  var body: some View {
    StructuredText(markdown: text)
      .textual.textSelection(.enabled)
      .textual.headingStyle(GachaHeadingStyle())
      .textual.blockQuoteStyle(GachaBlockQuoteStyle())
      .opacity(0.82)
      .onHover { hovering in
        if hovering {
          NSCursor.iBeam.push()
        } else {
          NSCursor.pop()
        }
      }
  }
}

private struct GachaHeadingStyle: StructuredText.HeadingStyle {
  private static let fontScales: [CGFloat] = [2.5, 1.75, 1.25, 1.0, 1.0, 1.0]
  private static let alphas: [CGFloat] = [1.0, 0.9, 0.75, 0.5, 0.5, 0.5]
  private static let topSpacings: [CGFloat] = [1.2, 1.1, 1.0, 1.0, 1.0, 1.0]
  private static let bottomSpacings: [CGFloat] = [1.0, 0.55, 0.5, 0.5, 0.5, 0.5]

  @Environment(\.colorScheme) private var colorScheme

  func makeBody(configuration: Configuration) -> some View {
    let level = max(1, min(configuration.headingLevel, 6))
    let index = level - 1

    configuration.label
      .textual.fontScale(Self.fontScales[index])
      .fontWeight(.semibold)
      .foregroundStyle(headingColor(level: level))
      .textual.blockSpacing(
        .fontScaled(
          top: Self.topSpacings[index],
          bottom: Self.bottomSpacings[index]))
  }

  private func headingColor(level: Int) -> Color {
    let alpha = Self.alphas[max(0, min(level - 1, Self.alphas.count - 1))]
    let base: Color = colorScheme == .dark ? .white : .black
    return base.opacity(alpha)
  }
}

private struct GachaBlockQuoteStyle: StructuredText.BlockQuoteStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .frame(maxWidth: .infinity, alignment: .leading)
      .foregroundStyle(.secondary)
      .textual.padding(.leading, .fontScaled(1))
      .textual.padding([.top, .bottom], .fontScaled(0.35))
      .background(alignment: .leading) {
        Rectangle()
          .fill(Color.secondary.opacity(0.6))
          .frame(width: 3)
      }
  }
}
