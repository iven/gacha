import AppKit

@MainActor
struct DeletionConfirmationAlert {
  var messageText: String
  var informativeText: String
  var deleteTitle: String
  var cancelTitle: String

  func present(for window: NSWindow, confirmed: @escaping () -> Void) {
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = messageText
    alert.informativeText = informativeText
    alert.addButton(withTitle: deleteTitle)
    let cancelButton = alert.addButton(withTitle: cancelTitle)
    cancelButton.keyEquivalent = "\u{1b}"

    alert.beginSheetModal(for: window) { response in
      guard response == .alertFirstButtonReturn else {
        return
      }

      confirmed()
    }
  }
}
