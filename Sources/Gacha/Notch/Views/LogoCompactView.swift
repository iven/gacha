import SwiftUI

struct LogoCompactView: View {
  var body: some View {
    Text("G")
      .font(.system(size: 11, weight: .bold))
      .foregroundStyle(.white)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(.red, in: Capsule())
  }
}
