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

  /// Whether the card management window is currently visible, used by the
  /// notch toolbar to render the preview toggle and reflect the edit button's
  /// "active" state.
  @Published private(set) var cardWindowVisible = false {
    didSet { refreshManagedWindowState() }
  }

  /// Whether the settings window is currently visible, used by the notch
  /// toolbar to reflect the settings button's "active" state.
  @Published private(set) var settingsVisible = false {
    didSet { refreshManagedWindowState() }
  }

  /// Edge-triggered "user requested toggling preview from the notch toolbar".
  /// CardManagementModel subscribes to this and calls togglePreview() so the
  /// model stays the single owner of preview state.
  let togglePreviewRequest = PassthroughSubject<Void, Never>()

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
