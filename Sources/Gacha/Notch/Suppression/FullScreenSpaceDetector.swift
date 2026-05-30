import Foundation

/// Detects whether the visible Space on any display is a full-screen Space,
/// using the private CoreGraphics Spaces API.
///
/// Comparing window bounds against the screen frame does not work: a real
/// full-screen window lives on its own Space, so once the transition settles an
/// on-screen window query no longer returns it. Reading the Space type stays
/// correct for the whole duration the user is in full screen.
///
/// Space type constants (verified against alt-tab-macos, yabai, macos-corelibs):
///   0 user, 2 system, 3 tiled (Split View), 4 fullscreen.
struct FullScreenSpaceDetector: SuppressionProbing {
  private let fullscreenSpaceType = 4

  func isSuppressingStateActive() -> Bool {
    guard
      let displays = CGSCopyManagedDisplaySpaces(CGSMainConnectionID())
        as? [[String: Any]]
    else {
      return false
    }

    for display in displays {
      guard
        let current = display["Current Space"] as? [String: Any],
        let type = current["type"] as? Int
      else {
        continue
      }

      if type == fullscreenSpaceType {
        return true
      }
    }

    return false
  }
}
