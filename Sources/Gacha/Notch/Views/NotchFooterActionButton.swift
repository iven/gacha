import SwiftUI

struct NotchFooterActionButton: View {
  let label: String
  let tint: Color
  var hint: String?
  var showKeyboardHints = true
  var isEnabled = true
  let action: () -> Void

  var body: some View {
    HoverButton(action: action) { hovering in
      labelWithHint
        .foregroundStyle(.white.opacity(hovering && isEnabled ? 1.0 : 0.75))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
          tint.opacity(hovering && isEnabled ? 0.55 : 0.35),
          in: RoundedRectangle(cornerRadius: 6)
        )
    }
    .disabled(!isEnabled)
    .opacity(isEnabled ? 1.0 : 0.45)
  }

  private var labelWithHint: Text {
    let main = Text(label)
    guard showKeyboardHints, let hint else { return main }
    let badge = Text(" \(hint)")
      .font(.system(size: 8, weight: .medium))
      .foregroundStyle(.white.opacity(0.55))
    return main + badge
  }
}
