import AppKit
import Combine
import DynamicNotchKit
import SwiftUI

@MainActor
final class PresentationController {
  private var notch: DynamicNotch<AnyView, AnyView, AnyView>?
  private var hoverObservation: AnyCancellable?

  func start() {
    let notch = DynamicNotch(
      hoverBehavior: .all,
      style: .notch,
      expanded: { AnyView(PreviewExpandedView()) },
      compactLeading: { AnyView(PreviewCompactLeadingView()) },
      compactTrailing: { AnyView(PreviewCompactLeadingView().hidden()) })
    self.notch = notch
    Task { await notch.compact() }
    hoverObservation =
      notch.$isHovering
      .removeDuplicates()
      .sink { [weak self] hovering in
        self?.handleHoverChange(hovering)
      }
  }

  private func handleHoverChange(_ hovering: Bool) {
    guard let notch else {
      return
    }

    Task {
      if hovering {
        await notch.expand()
      } else {
        await notch.compact()
      }
    }
  }
}

private struct PreviewCompactLeadingView: View {
  var body: some View {
    Text("G")
      .font(.system(size: 11, weight: .bold))
      .foregroundStyle(.white)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(.red, in: Capsule())
  }
}

private struct PreviewExpandedView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("serendipity")
        .font(.title2.bold())
      Text("/ˌserənˈdipədē/")
        .foregroundStyle(.secondary)
      Text("n. 意外发现美好事物的能力")
      Divider()
        .padding(.vertical, 8)
      HStack(spacing: 8) {
        ForEach(["陌生", "模糊", "熟悉", "精通"], id: \.self) { label in
          Text(label)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
        }
      }
    }
    .padding(16)
    .frame(width: 480)
  }
}
