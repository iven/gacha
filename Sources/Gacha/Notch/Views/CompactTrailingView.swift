import AppKit
import SwiftUI

struct CompactTrailingView: View {
  @ObservedObject var viewModel: NotchViewModel
  @State private var isHovering = false

  var body: some View {
    if viewModel.isPaused {
      pauseButton
    } else {
      pauseButton.hidden()
    }
  }

  private var pauseButton: some View {
    Button {
      viewModel.onResumeRequested?()
    } label: {
      Image(systemName: isHovering ? "play.fill" : "pause.fill")
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isHovering ? Color.blue : Color.clear, in: Capsule())
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      isHovering = hovering
      if hovering {
        NSCursor.pointingHand.push()
      } else {
        NSCursor.pop()
      }
    }
  }
}
