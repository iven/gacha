import AppKit
import SwiftUI

extension View {
  /// Uses the app icon as the alert dialog icon.
  func appDialogIcon() -> some View {
    dialogIcon(Image(nsImage: NSApp.applicationIconImage))
  }
}
