import SwiftUI

/// Button wrapper that tracks hover state and exposes it to the `label`
/// closure, so each call site decides what changes on hover (background,
/// glyph swap, foreground opacity, etc.). The cursor is left untouched.
struct HoverButton<Label: View>: View {
  let action: () -> Void
  @ViewBuilder let label: (Bool) -> Label

  @State private var isHovering = false

  var body: some View {
    Button(action: action) {
      label(isHovering)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      isHovering = hovering
    }
  }
}
