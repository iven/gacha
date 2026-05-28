import AppKit
import SwiftUI

/// Bridges a SwiftUI view's hosting `NSWindow` back out to the SwiftUI layer
/// so AppKit modal sheets (`beginSheetModal(for:)`) can be anchored to it.
struct WindowAccessor: NSViewRepresentable {
  let onResolve: (NSWindow?) -> Void

  func makeNSView(context: Context) -> NSView {
    let view = NSView()
    DispatchQueue.main.async { onResolve(view.window) }
    return view
  }

  func updateNSView(_ nsView: NSView, context: Context) {}
}
