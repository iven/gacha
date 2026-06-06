import SwiftUI

struct NotchCompactTrailingView: View {
  @ObservedObject var viewModel: NotchControllerViewModel

  var body: some View {
    ZStack {
      if viewModel.isSuppressed {
        suppressionIndicator
          .transition(indicatorTransition)
      } else if viewModel.isPaused {
        pauseButton
          .transition(indicatorTransition)
      } else if viewModel.showsNoticeCount, viewModel.noticeCount > 0 {
        NoticeCountIndicator(
          count: viewModel.noticeCount,
          pulseTriggerID: viewModel.noticeCountPulseTriggerID,
          handledPulseTriggerID: handledNoticeCountPulseTriggerID
        )
        .transition(indicatorTransition)
      } else {
        pauseButton.hidden()
          .transition(.opacity)
      }
    }
    .animation(.easeInOut(duration: 0.22), value: viewModel.isSuppressed)
    .animation(.easeInOut(duration: 0.22), value: viewModel.isPaused)
    .animation(.easeInOut(duration: 0.22), value: viewModel.showsNoticeCount)
    .animation(.easeInOut(duration: 0.22), value: viewModel.noticeCount > 0)
  }

  // Suppression is system-driven and clears on its own, so there is nothing to tap.
  private var suppressionIndicator: some View {
    Image(systemName: "eye.slash.fill")
      .font(.system(size: NotchToolbarStyle.compactGlyphFontSize, weight: .bold))
      .foregroundStyle(.white.opacity(0.85))
      .notchToolbarControl(restingShell: false)
      .contentShape(Rectangle())
      .help(NotchStrings.suppressionIndicatorHint)
  }

  private var pauseButton: some View {
    HoverButton(action: { viewModel.onResumeRequested?() }) { hovering in
      Image(systemName: hovering ? "play.fill" : "pause.fill")
        .font(.system(size: NotchToolbarStyle.compactGlyphFontSize, weight: .bold))
        .foregroundStyle(.white.opacity(0.85))
        .notchToolbarControl(restingShell: false, highlighted: hovering)
    }
  }

  private var indicatorTransition: AnyTransition {
    .opacity.combined(with: .scale(scale: 0.86))
  }

  private var handledNoticeCountPulseTriggerID: Binding<Int> {
    Binding(
      get: { viewModel.handledNoticeCountPulseTriggerID },
      set: { viewModel.handledNoticeCountPulseTriggerID = $0 })
  }
}
