import SwiftUI

struct LogoCompactView: View {
  // Mirrors icon.json's G-avenir gradient: rose at top, fully white at y=0.72.
  private static let gFill = LinearGradient(
    stops: [
      .init(color: Color(red: 1.0, green: 0.353, blue: 0.401), location: 0),
      .init(color: .white, location: 0.72),
    ],
    startPoint: .top,
    endPoint: .bottom
  )

  // Sampled from the rendered icon: 1-Sphere glass layer composited onto the
  // system-dark canvas.
  private static let shellBody = Color(red: 30 / 255, green: 30 / 255, blue: 30 / 255)

  // Approximates `glass: true`'s top specular: bright rim fading to nothing.
  private static let shellRim = LinearGradient(
    colors: [.white.opacity(0.22), .clear],
    startPoint: .top,
    endPoint: .bottom
  )

  var body: some View {
    Text("G")
      .font(.custom("Avenir-Black", size: 11))
      .foregroundStyle(Self.gFill)
      .opacity(0.8)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background {
        Capsule()
          .fill(Self.shellBody)
          .overlay(Capsule().strokeBorder(Self.shellRim, lineWidth: 0.5))
      }
  }
}
