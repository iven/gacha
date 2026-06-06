import SwiftUI

struct NotchToolbarButton: View {
  let symbol: String
  var isActive = false
  let action: () -> Void

  var body: some View {
    HoverButton(action: action) { hovering in
      Image(systemName: symbol)
        .resizable()
        .scaledToFit()
        .frame(
          width: NotchToolbarStyle.glyphSize,
          height: NotchToolbarStyle.glyphSize
        )
        .foregroundStyle(.white.opacity(hovering ? 1.0 : 0.85))
        .notchToolbarControl(highlighted: isActive || hovering)
    }
  }
}
