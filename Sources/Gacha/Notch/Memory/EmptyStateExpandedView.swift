import SwiftUI

struct EmptyStateExpandedView: View {
  let action: () -> Void
  let onOpenSettings: () -> Void
  var isSettingsVisible: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        LogoCompactView()
        Spacer()
        toolButton(symbol: "gearshape", isActive: isSettingsVisible) {
          onOpenSettings()
        }
      }

      VStack(spacing: 12) {
        Text(NotchStrings.emptyStateTitle)
          .font(.title.bold())
          .multilineTextAlignment(.center)
        Text(NotchStrings.emptyStateBody)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
        Button(action: action) {
          Text(NotchStrings.emptyStateAction)
            .frame(maxWidth: .infinity, minHeight: 32)
        }
        .buttonStyle(.borderedProminent)
        .frame(width: 160)
        .padding(.top, 24)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 36)
    }
    .padding(.horizontal, 12)
    .padding(.bottom, 12)
    .frame(width: 480)
  }

  private func toolButton(
    symbol: String, isActive: Bool = false, action: @escaping () -> Void
  ) -> some View {
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
