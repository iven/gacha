import Foundation
import Testing

@testable import Gacha

@MainActor
@Test func toggleShortcutUnpinsAndReappliesPresentation() throws {
  let fixture = try MemoryNotchPresenterFixture()
  let presenter = fixture.presenter

  // Enter pinned mode the way the toolbar/`p` shortcut does.
  presenter.handleTogglePin()
  #expect(presenter.mode == .pinned)

  var presentationStateChanges = 0
  var toggleRequests = 0
  presenter.onPresentationStateChanged = { presentationStateChanges += 1 }
  presenter.onToggleRequested = { toggleRequests += 1 }

  presenter.handleToggleShortcut()

  // Releasing a pin via the global toggle shortcut returns to the scheduler and
  // re-applies presentation state (so auto-collapse resumes), instead of
  // delegating to the controller's expand/collapse toggle.
  #expect(presenter.mode == .scheduler)
  #expect(presentationStateChanges == 1)
  #expect(toggleRequests == 0)
}

@MainActor
private final class MemoryNotchPresenterFixture {
  let presenter: MemoryNotchPresenter
  private let rootURL: URL

  init() throws {
    rootURL = URL(fileURLWithPath: "/tmp/agents/GachaTests/\(UUID().uuidString)")
    let directories = AppDirectories(
      applicationSupportURL: rootURL.appendingPathComponent("Application Support"),
      userStorageURL: rootURL.appendingPathComponent("Documents"))
    let repository = try MemoryCardRepository(directories: directories)
    let settingsStore = SettingsStore(
      defaults: UserDefaults(suiteName: "MemoryNotchPresenterTests-\(UUID().uuidString)")!)
    let cardWindowBridge = CardWindowBridge(
      windowOpenActionRegistry: WindowOpenActionRegistry())
    presenter = MemoryNotchPresenter(
      memoryCardRepository: repository,
      settingsStore: settingsStore,
      cardWindowBridge: cardWindowBridge)
  }

  deinit {
    try? FileManager.default.removeItem(at: rootURL)
  }
}
