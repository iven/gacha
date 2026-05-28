import AppKit
import SwiftUI

struct MemoryCardExpandedView: View {
  let card: MemoryCard
  let actions: MemoryCardActions
  var isInteractive: Bool = true
  @ObservedObject var autoCollapseSchedule: NotchAutoCollapseSchedule

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
      ScrollView(.vertical) {
        bodyView
      }
      .padding(.vertical, 12)
      AutoCollapseProgressBar(schedule: autoCollapseSchedule)
      HStack(spacing: 8) {
        if isDue {
          ratingButton(NotchStrings.ratingAgain, tint: .ratingAgain, rating: .again, hint: "1")
          ratingButton(NotchStrings.ratingHard, tint: .ratingHard, rating: .hard, hint: "2")
          ratingButton(NotchStrings.ratingGood, tint: .ratingGood, rating: .good, hint: "3")
          ratingButton(NotchStrings.ratingEasy, tint: .ratingEasy, rating: .easy, hint: "4")
        } else {
          ratingButton("", tint: .ratingAgain, rating: .again, hint: nil)
            .hidden()
            .allowsHitTesting(false)
          ratingButton("", tint: .ratingHard, rating: .hard, hint: nil)
            .hidden()
            .allowsHitTesting(false)
          ratingButton("", tint: .ratingGood, rating: .good, hint: nil)
            .hidden()
            .allowsHitTesting(false)
          nextButton
        }
      }
      .disabled(!isInteractive)
    }
    .padding(.horizontal, 12)
    .padding(.bottom, 12)
    .frame(width: Self.cardWidth, alignment: .leading)
    .frame(maxHeight: cardMaxHeight, alignment: .top)
    .background(KeyEventHandlingView(onKeyDown: handleKeyDown))
  }

  private func handleKeyDown(_ event: NSEvent) -> Bool {
    let characters = event.charactersIgnoringModifiers ?? ""
    if isDue {
      switch characters {
      case "1":
        actions.onRate(card, .again)
        return true
      case "2":
        actions.onRate(card, .hard)
        return true
      case "3":
        actions.onRate(card, .good)
        return true
      case "4":
        actions.onRate(card, .easy)
        return true
      default: return false
      }
    } else if characters == " " {
      actions.onNext(card)
      return true
    }
    return false
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
      labelWithHint(NotchStrings.ratingNext, hint: "␣")
        .foregroundStyle(.white.opacity(0.75))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.ratingNext.opacity(0.35), in: RoundedRectangle(cornerRadius: 6))
    }
    .buttonStyle(.plain)
  }

  private func ratingButton(
    _ label: String, tint: Color, rating: MemoryCardRating, hint: String?
  ) -> some View {
    Button {
      actions.onRate(card, rating)
    } label: {
      labelWithHint(label, hint: hint)
        .foregroundStyle(.white.opacity(0.75))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(0.35), in: RoundedRectangle(cornerRadius: 6))
    }
    .buttonStyle(.plain)
  }

  private func labelWithHint(_ label: String, hint: String?) -> Text {
    let main = Text(label)
    guard let hint else { return main }
    let badge = Text(" \(hint)")
      .font(.system(size: 8, weight: .medium))
      .foregroundStyle(.white.opacity(0.55))
    return main + badge
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
        .background(.white.opacity(0.2), in: Capsule())
    }
    .buttonStyle(.plain)
  }
}
