import AppKit
import Carbon.HIToolbox
import SwiftUI

struct MemoryCardExpandedView: View {
  let card: MemoryCard
  let actions: MemoryCardActions
  var isInteractive: Bool = true
  var isPinned: Bool = false
  var isCardWindowVisible: Bool = false
  var isSettingsVisible: Bool = false
  var showKeyboardHints: Bool = true
  @ObservedObject var autoCollapseSchedule: NotchAutoCollapseSchedule

  var body: some View {
    NotchExpandedCardScaffold(
      autoCollapseSchedule: autoCollapseSchedule,
      onKeyDown: handleKeyDown,
      toolbar: {
        NotchToolbarButton(symbol: pinSymbol, isActive: isPinned) {
          actions.onTogglePin()
        }
        NotchToolbarButton(symbol: "pause") {
          actions.onPause()
        }
        NotchToolbarButton(symbol: "square.and.pencil", isActive: isCardWindowVisible) {
          actions.onEditCard(card)
        }
        NotchToolbarButton(symbol: "gearshape", isActive: isSettingsVisible) {
          actions.onOpenSettings()
        }
      },
      content: {
        bodyView
      },
      footer: {
        HStack(spacing: 8) {
          if isDue {
            rateButton(NotchStrings.ratingAgain, tint: .ratingAgain, rating: .again, hint: "1")
            rateButton(NotchStrings.ratingHard, tint: .ratingHard, rating: .hard, hint: "2")
            rateButton(NotchStrings.ratingGood, tint: .ratingGood, rating: .good, hint: "3")
            rateButton(NotchStrings.ratingEasy, tint: .ratingEasy, rating: .easy, hint: "4")
          } else {
            rateButton("", tint: .ratingAgain, rating: .again, hint: nil)
              .hidden()
              .allowsHitTesting(false)
            rateButton("", tint: .ratingHard, rating: .hard, hint: nil)
              .hidden()
              .allowsHitTesting(false)
            rateButton("", tint: .ratingGood, rating: .good, hint: nil)
              .hidden()
              .allowsHitTesting(false)
            actionButton(
              NotchStrings.ratingNext, tint: .ratingNext, hint: "→"
            ) {
              actions.onNext(card)
            }
          }
        }
        .disabled(!isInteractive)
      })
  }

  private func handleKeyDown(_ event: NSEvent) -> Bool {
    if Int(event.keyCode) == kVK_Escape {
      actions.onDismiss()
      return true
    }
    let characters = event.charactersIgnoringModifiers ?? ""
    if characters == "p" {
      actions.onTogglePin()
      return true
    }
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
    } else if Int(event.keyCode) == kVK_RightArrow {
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

  // The leftmost toolbar slot toggles pin (no card window) or preview (with
  // card window). Symbol switches between pin and eye accordingly; .fill
  // variant indicates the notch is currently held.
  private var pinSymbol: String {
    let base = isCardWindowVisible ? "eye" : "pin"
    return isPinned ? "\(base).fill" : base
  }

  private func rateButton(
    _ label: String, tint: Color, rating: MemoryCardRating, hint: String?
  ) -> some View {
    actionButton(label, tint: tint, hint: hint) { actions.onRate(card, rating) }
  }

  private func actionButton(
    _ label: String, tint: Color, hint: String?, action: @escaping () -> Void
  ) -> some View {
    NotchFooterActionButton(
      label: label,
      tint: tint,
      hint: hint,
      showKeyboardHints: showKeyboardHints,
      action: action)
  }

}
