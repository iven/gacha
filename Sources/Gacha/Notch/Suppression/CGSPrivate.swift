import CoreGraphics

// Private CoreGraphics window-server symbols for querying Spaces. macOS exposes
// no public API to tell whether the visible Space is a full-screen one, so this
// binds the same symbols long used by WhichSpace, Spaceman, and similar tools.
// Isolated here so the dependency stays swappable if the system ever changes.

typealias CGSConnectionID = UInt32

@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> CGSConnectionID

/// Returns one dictionary per display, each with a `Spaces` array and a
/// `Current Space` entry. A space dictionary carries a numeric `type`:
/// 0 user, 2 system, 3 tiled (Split View), 4 fullscreen.
@_silgen_name("CGSCopyManagedDisplaySpaces")
func CGSCopyManagedDisplaySpaces(_ connection: CGSConnectionID) -> CFArray
