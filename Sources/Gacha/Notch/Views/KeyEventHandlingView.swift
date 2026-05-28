import AppKit
import SwiftUI

struct KeyEventHandlingView: NSViewRepresentable {
  let onKeyDown: (NSEvent) -> Bool

  func makeNSView(context: Context) -> KeyEventHandlingNSView {
    let view = KeyEventHandlingNSView()
    view.onKeyDown = onKeyDown
    return view
  }

  func updateNSView(_ nsView: KeyEventHandlingNSView, context: Context) {
    nsView.onKeyDown = onKeyDown
  }
}

final class KeyEventHandlingNSView: NSView {
  var onKeyDown: ((NSEvent) -> Bool)?

  override var acceptsFirstResponder: Bool { true }

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    DispatchQueue.main.async { [weak self] in
      guard let self, let window = self.window else { return }
      window.makeFirstResponder(self)
    }
  }

  override func keyDown(with event: NSEvent) {
    if onKeyDown?(event) == true { return }
    super.keyDown(with: event)
  }
}
