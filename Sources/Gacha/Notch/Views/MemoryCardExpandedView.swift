import AppKit
import SwiftUI

struct MemoryCardExpandedView: View {
  let card: MemoryCard
  let actions: MemoryCardActions

  // DynamicNotchKit panel = screen.width/2 × screen.height/2, with the expanded
  // content sitting inside safeAreaInsets reserving the notch height on top and
  // 48pt on each remaining edge (NotchView.swift). The card height fills the
  // available area; the width is the PRD-specified design width.
  private static let dynamicNotchKitEdgeInset: CGFloat = 48
  private static let cardWidth: CGFloat = 480

  private var cardMaxHeight: CGFloat {
    let screen = NSScreen.main
    let panelHeight = (screen?.frame.height ?? 800) / 2
    let topInset = screen?.safeAreaInsets.top ?? 32
    return panelHeight - topInset - Self.dynamicNotchKitEdgeInset
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        LogoCompactView()
        Spacer()
        toolButton(symbol: "square.and.pencil") {
          actions.onEditCard(card)
        }
        toolButton(symbol: "gearshape", action: actions.onSettings)
      }
      .padding(.bottom, 4)
      ScrollView(.vertical) {
        bodyView
      }
      .padding(.vertical, 12)
      Divider()
        .padding(.vertical, 4)
      HStack(spacing: 8) {
        if isDue {
          ratingButton(NotchStrings.ratingAgain, tint: .ratingAgain, rating: .again)
          ratingButton(NotchStrings.ratingHard, tint: .ratingHard, rating: .hard)
          ratingButton(NotchStrings.ratingGood, tint: .ratingGood, rating: .good)
          ratingButton(NotchStrings.ratingEasy, tint: .ratingEasy, rating: .easy)
        } else {
          ratingButton("", tint: .ratingAgain, rating: .again)
            .hidden()
            .allowsHitTesting(false)
          ratingButton("", tint: .ratingHard, rating: .hard)
            .hidden()
            .allowsHitTesting(false)
          ratingButton("", tint: .ratingGood, rating: .good)
            .hidden()
            .allowsHitTesting(false)
          nextButton
        }
      }
    }
    .padding(.horizontal, 8)
    .padding(.bottom, 8)
    .frame(width: Self.cardWidth, alignment: .leading)
    .frame(maxHeight: cardMaxHeight, alignment: .top)
  }

  @ViewBuilder
  private var bodyView: some View {
    let trimmed = card.body.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      Text(NotchStrings.emptyBodyPlaceholder)
        .font(.title3)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    } else {
      MarkdownRenderer(text: trimmed)
        .environment(\.colorScheme, .dark)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var isDue: Bool {
    actions.isDue(card)
  }

  private var nextButton: some View {
    Button {
      actions.onNext(card)
    } label: {
      Text(NotchStrings.ratingNext)
        .foregroundStyle(.white.opacity(0.8))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.ratingNext.opacity(0.25), in: RoundedRectangle(cornerRadius: 6))
    }
    .buttonStyle(.plain)
    .pointingCursor(.arrow)
  }

  private func ratingButton(_ label: String, tint: Color, rating: MemoryCardRating) -> some View {
    Button {
      actions.onRate(card, rating)
    } label: {
      Text(label)
        .foregroundStyle(.white.opacity(0.8))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(0.25), in: RoundedRectangle(cornerRadius: 6))
    }
    .buttonStyle(.plain)
    .pointingCursor(.arrow)
  }

  private func toolButton(symbol: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: symbol)
        .resizable()
        .scaledToFit()
        .frame(width: 14, height: 14)
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.white.opacity(0.12), in: Capsule())
    }
    .buttonStyle(.plain)
    .pointingCursor(.arrow)
  }
}
