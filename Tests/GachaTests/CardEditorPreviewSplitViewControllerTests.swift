import AppKit
import Testing

@testable import Gacha

@MainActor
@Test func textPaneCatchesClicksOnlyWhenEnabled() {
  let pane = CardTextPaneViewController()
  pane.view.frame = NSRect(x: 0, y: 0, width: 300, height: 200)
  pane.view.layoutSubtreeIfNeeded()

  pane.setClickHandlingEnabled(true)
  #expect(pane.view.hitTest(NSPoint(x: 10, y: 10)) === pane.view)

  pane.setClickHandlingEnabled(false)
  #expect(pane.view.hitTest(NSPoint(x: 10, y: 10)) !== pane.view)
}
