import AppKit
import SwiftUI

struct NotchExpandedCardScaffold<Toolbar: View, Content: View, Footer: View>: View {
  @ObservedObject var autoCollapseSchedule: NotchAutoCollapseSchedule
  let onKeyDown: (NSEvent) -> Bool
  let toolbar: () -> Toolbar
  let content: () -> Content
  let footer: () -> Footer

  // DynamicNotchKit panel = screen.width/2 x screen.height/2, with expanded
  // content sitting inside safeAreaInsets reserving the notch height on top and
  // 48pt on each remaining edge.
  init(
    autoCollapseSchedule: NotchAutoCollapseSchedule,
    onKeyDown: @escaping (NSEvent) -> Bool,
    @ViewBuilder toolbar: @escaping () -> Toolbar,
    @ViewBuilder content: @escaping () -> Content,
    @ViewBuilder footer: @escaping () -> Footer
  ) {
    self.autoCollapseSchedule = autoCollapseSchedule
    self.onKeyDown = onKeyDown
    self.toolbar = toolbar
    self.content = content
    self.footer = footer
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        LogoCompactView()
        Spacer()
        toolbar()
      }
      ScrollView(.vertical) {
        content()
      }
      .padding(.vertical, 12)
      AutoCollapseProgressBar(schedule: autoCollapseSchedule)
      footer()
    }
    .padding(.horizontal, 12)
    .padding(.bottom, 12)
    .frame(width: NotchExpandedCardScaffoldMetrics.cardWidth, alignment: .leading)
    .frame(maxHeight: cardMaxHeight, alignment: .top)
    .background(KeyEventHandlingView(onKeyDown: onKeyDown))
  }

  private var cardMaxHeight: CGFloat {
    let screen = NSScreen.main
    let panelHeight = (screen?.frame.height ?? 800) / 2
    let topInset = screen?.safeAreaInsets.top ?? 32
    return panelHeight - topInset - NotchExpandedCardScaffoldMetrics.dynamicNotchKitEdgeInset
  }
}

private enum NotchExpandedCardScaffoldMetrics {
  static let dynamicNotchKitEdgeInset: CGFloat = 48
  static let cardWidth: CGFloat = 480
}
