import AppKit
import Testing

@testable import Gacha

@MainActor
@Test func editorCatchesClicksOnlyWhenEnabled() {
  let editor = CardEditorViewController()
  editor.view.frame = NSRect(x: 0, y: 0, width: 300, height: 200)
  editor.view.layoutSubtreeIfNeeded()

  editor.setClickHandlingEnabled(true)
  #expect(editor.view.hitTest(NSPoint(x: 10, y: 10)) === editor.view)

  editor.setClickHandlingEnabled(false)
  #expect(editor.view.hitTest(NSPoint(x: 10, y: 10)) !== editor.view)
}
