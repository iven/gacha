import AppKit
import Combine
import DynamicNotchKit
import SwiftUI

@MainActor
final class PresentationController {
  var onNewCardRequested: (() -> Void)?

  private var notch: DynamicNotch<AnyView, AnyView, AnyView>?
  private var hoverObservation: AnyCancellable?

  func start() {
    let notch = DynamicNotch(
      hoverBehavior: .all,
      style: .notch,
      expanded: {
        AnyView(EmptyStateExpandedView(action: { [weak self] in self?.handleNewCardRequest() }))
      },
      compactLeading: { AnyView(LogoCompactView()) },
      compactTrailing: { AnyView(LogoCompactView().hidden()) })
    self.notch = notch
    Task { await notch.compact() }
    hoverObservation =
      notch.$isHovering
      .removeDuplicates()
      .sink { [weak self] hovering in
        self?.handleHoverChange(hovering)
      }
  }

  private func handleNewCardRequest() {
    onNewCardRequested?()
  }

  private func handleHoverChange(_ hovering: Bool) {
    guard let notch else {
      return
    }

    Task {
      if hovering {
        await notch.expand()
        notch.windowController?.window?.makeKey()
      } else {
        await notch.compact()
      }
    }
  }
}

private struct LogoCompactView: View {
  var body: some View {
    Text("G")
      .font(.system(size: 11, weight: .bold))
      .foregroundStyle(.white)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(.red, in: Capsule())
  }
}

private struct EmptyStateExpandedView: View {
  let action: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      Text(PresentationStrings.emptyStateTitle)
        .font(.title.bold())
        .multilineTextAlignment(.center)
      Text(PresentationStrings.emptyStateBody)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      Button(action: action) {
        Text(PresentationStrings.emptyStateAction)
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

private struct MemoryCardExpandedView: View {
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
