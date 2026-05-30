import AppKit
import SwiftUI

/// Bridges a SwiftUI view's hosting `NSWindow` back out to the SwiftUI layer
/// so AppKit modal sheets (`beginSheetModal(for:)`) can be anchored to it.
struct WindowAccessor: NSViewRepresentable {
  let onResolve: (NSWindow?) -> Void

  func makeNSView(context: Context) -> NSView {
    let view = Backing()
    view.onResolve = onResolve
    return view
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    guard let view = nsView as? Backing else {
      return
    }
    view.onResolve = onResolve
  }

  final class Backing: NSView {
    var onResolve: ((NSWindow?) -> Void)?

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      DispatchQueue.main.async { [weak self] in
        guard let self else { return }
        self.onResolve?(self.window)
      }
    }
  }
}
