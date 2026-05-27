import SwiftUI

struct EmptyStateExpandedView: View {
  let action: () -> Void

  var body: some View {
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
    .padding(48)
    .frame(width: 480)
  }
}
