import SwiftUI

struct LogoCompactView: View {
  // Mirrors icon.json's G-avenir gradient: rose at top, fully white at y=0.72.
  private static let gFill = LinearGradient(
    stops: [
      .init(color: Color(red: 1.0, green: 0.353, blue: 0.401), location: 0),
      .init(color: Color(red: 1.0, green: 0.863, blue: 0.84), location: 0.72),
    ],
    startPoint: .top,
    endPoint: .bottom
  )

  var body: some View {
    Text("G")
      .font(.custom("Avenir-Black", size: NotchToolbarStyle.compactGlyphFontSize))
      .foregroundStyle(Self.gFill)
      .opacity(0.8)
      .notchToolbarControl()
  }
}
