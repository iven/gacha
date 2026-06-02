import CoreGraphics

// Private CoreGraphics window-server symbols. macOS exposes no public API for
// full-screen Space detection or screen-capture detection, so this binds the
// same symbols used by alt-tab-macos, Spaceman, and similar tools.
// Isolated here so the dependency stays swappable if the system ever changes.

typealias CGSConnectionID = UInt32

@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> CGSConnectionID

/// Returns one dictionary per display, each with a `Spaces` array and a
/// `Current Space` entry. A space dictionary carries a numeric `type`:
/// 0 user, 2 system, 3 tiled (Split View), 4 fullscreen.
@_silgen_name("CGSCopyManagedDisplaySpaces")
func CGSCopyManagedDisplaySpaces(_ connection: CGSConnectionID) -> CFArray

/// Returns true when something is capturing the screen — QuickTime screen
/// recording, Zoom/TencentMeeting screen sharing, and similar tools all
/// trigger this. Verified by local testing; the header comment's "remote
/// desktop only?" question mark is misleading.
@_silgen_name("CGSIsScreenWatcherPresent")
func CGSIsScreenWatcherPresent() -> Bool
