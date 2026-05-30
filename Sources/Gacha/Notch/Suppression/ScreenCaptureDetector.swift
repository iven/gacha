import Foundation

/// Detects whether the screen is currently being captured — QuickTime screen
/// recording, Zoom/TencentMeeting screen sharing, and similar tools are all
/// covered. Uses `CGSIsScreenWatcherPresent`, verified by local testing.
struct ScreenCaptureDetector: SuppressionProbing {
  func isSuppressingStateActive() -> Bool {
    CGSIsScreenWatcherPresent()
  }
}
