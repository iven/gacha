import SwiftUI

enum NotchToolbarStyle {
  static let controlWidth: CGFloat = 30
  static let controlHeight: CGFloat = 22
  static let glyphSize: CGFloat = 14
  static let compactGlyphFontSize: CGFloat = 11

  // Sampled from the rendered icon: 1-Sphere glass layer composited onto the
  // system-dark canvas.
  private static let shellBody = Color(red: 30 / 255, green: 30 / 255, blue: 30 / 255)

  // Approximates `glass: true`'s top specular: bright rim fading to nothing.
  private static let shellRim = LinearGradient(
    colors: [.white.opacity(0.22), .clear],
    startPoint: .top,
    endPoint: .bottom
  )

  @ViewBuilder
  static func background(restingShell: Bool = true, highlighted: Bool = false) -> some View {
    if restingShell || highlighted {
      Capsule()
        .fill(shellBody)
        .overlay(Capsule().fill(Color.accentColor.opacity(highlighted ? 0.85 : 0)))
        .overlay(Capsule().strokeBorder(shellRim, lineWidth: 0.5))
    } else {
      Color.clear
    }
  }
}

extension View {
  // Lays a glyph into the standard notch toolbar control box: a fixed-size
  // capsule whose shell shows at rest and tints to the accent when highlighted.
  // `restingShell: false` keeps the box transparent until highlighted.
  func notchToolbarControl(restingShell: Bool = true, highlighted: Bool = false) -> some View {
    frame(width: NotchToolbarStyle.controlWidth, height: NotchToolbarStyle.controlHeight)
      .background {
        NotchToolbarStyle.background(restingShell: restingShell, highlighted: highlighted)
      }
  }
}
