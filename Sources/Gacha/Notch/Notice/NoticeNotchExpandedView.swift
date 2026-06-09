import AppKit
import Carbon.HIToolbox
import SwiftUI

struct NoticeNotchExpandedView: View {
  @ObservedObject var presenter: NoticeNotchPresenter
  @ObservedObject var autoCollapseSchedule: NotchAutoCollapseSchedule

  var body: some View {
    if let message = presenter.currentMessage {
      expandedCard(message: message)
    } else {
      EmptyView()
    }
  }

  private func expandedCard(message: NoticeMessage) -> some View {
    NotchExpandedCardScaffold(
      autoCollapseSchedule: autoCollapseSchedule,
      onKeyDown: handleKeyDown,
      toolbar: {
        NotchToolbarButton(symbol: "pause") {
          presenter.actions.onPause()
        }
        NotchToolbarButton(symbol: "gearshape", isActive: presenter.isSettingsVisible) {
          presenter.actions.onOpenSettings()
        }
      },
      content: {
        MarkdownRenderer(text: message.markdown)
          .environment(\.colorScheme, .dark)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
      },
      footer: {
        HStack(spacing: 8) {
          placeholderActionButton
          placeholderActionButton
          placeholderActionButton
          NotchFooterActionButton(
            label: NotchStrings.noticeNext,
            tint: .ratingNext,
            hint: "→",
            isEnabled: presenter.canShowNext
          ) {
            presenter.actions.onNext()
          }
        }
      })
  }

  private func handleKeyDown(_ event: NSEvent) -> Bool {
    if Int(event.keyCode) == kVK_Escape {
      presenter.actions.onDismiss()
      return true
    }
    if Int(event.keyCode) == kVK_RightArrow, presenter.canShowNext {
      presenter.actions.onNext()
      return true
    }
    return false
  }

  private var placeholderActionButton: some View {
    NotchFooterActionButton(label: "", tint: .ratingNext, action: {})
      .hidden()
      .allowsHitTesting(false)
  }
}
