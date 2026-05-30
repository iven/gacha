import AppKit
import Combine

/// Shared state bridging the SwiftUI window scenes (card management, settings)
/// and the AppKit-driven notch presenter: scenes write here, the notch presenter
/// observes via Combine.
@MainActor
final class CardWindowBridge: ObservableObject {
  /// Card pinned to the notch by the window's preview toggle; `nil` clears it.
  @Published var previewCard: MemoryCard?

  /// Card the window should select when it next appears (notch ✏️ / edit flow).
  @Published var pendingEditCardID: String?

  /// Whether any Gacha-managed window (card management or settings) is visible,
  /// so the notch can skip its auto-collapse countdown while one is open.
  @Published private(set) var hasVisibleManagedWindow = false

  private var cardWindowVisible = false {
    didSet { refreshManagedWindowState() }
  }
  private var settingsVisible = false {
    didSet { refreshManagedWindowState() }
  }

  private let windowOpenActionRegistry: WindowOpenActionRegistry

  init(windowOpenActionRegistry: WindowOpenActionRegistry) {
    self.windowOpenActionRegistry = windowOpenActionRegistry
  }

  /// Opens the card window from any context (notch ✏️ / "new card"), optionally
  /// pre-selecting a card. AppKit-driven callers are not part of the SwiftUI
  /// scene tree, so opening is delegated to a scene-backed registry.
  func requestOpen(editingCardID: String? = nil) {
    if let editingCardID {
      pendingEditCardID = editingCardID
    }
    windowOpenActionRegistry.open(.cards)
  }

  func setCardWindowVisible(_ visible: Bool) {
    cardWindowVisible = visible
  }

  func setSettingsVisible(_ visible: Bool) {
    settingsVisible = visible
  }

  private func refreshManagedWindowState() {
    let visible = cardWindowVisible || settingsVisible
    // Accessory apps must flip to .regular for a window to come forward, and
    // back to .accessory once no managed window remains.
    if visible {
      NSApp.setActivationPolicy(.regular)
      NSApp.activate(ignoringOtherApps: true)
    } else {
      NSApp.setActivationPolicy(.accessory)
    }
    if hasVisibleManagedWindow != visible {
      hasVisibleManagedWindow = visible
    }
  }
}
