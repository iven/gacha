import Foundation
import Testing

@testable import Gacha

@MainActor
@Test func moveFreshTargetPublishesMoveConfirmation() throws {
  let fixture = makeCoordinatorFixture()
  try fixture.populateCurrentRoot()
  let target = fixture.scratchURL.appendingPathComponent("new-root", isDirectory: true)

  fixture.coordinator.routeMove(target: target)

  let confirmation = try #require(fixture.coordinator.confirmation)
  #expect(confirmation.intent == .move)
  #expect(confirmation.target == target)
  #expect(fixture.coordinator.notice == nil)
}

@MainActor
@Test func confirmingMovePublishesSuccessNoticeAndUpdatesSettings() throws {
  let fixture = makeCoordinatorFixture()
  try fixture.populateCurrentRoot()
  let target = fixture.scratchURL.appendingPathComponent("new-root", isDirectory: true)
  fixture.coordinator.routeMove(target: target)
  let confirmation = try #require(fixture.coordinator.confirmation)

  fixture.coordinator.runConfirmed(confirmation)

  switch fixture.coordinator.notice {
  case .success(let path):
    #expect(URL(fileURLWithPath: path).standardizedFileURL == target.standardizedFileURL)
  default:
    Issue.record("expected success notice, got \(String(describing: fixture.coordinator.notice))")
  }
  #expect(fixture.settingsStore.userStorageURL.standardizedFileURL == target.standardizedFileURL)
}

@MainActor
@Test func moveOntoOccupiedTargetPublishesErrorNotice() throws {
  let fixture = makeCoordinatorFixture()
  try fixture.populateCurrentRoot()
  let target = fixture.scratchURL.appendingPathComponent("occupied", isDirectory: true)
  try fixture.fileManager.createDirectory(at: target, withIntermediateDirectories: true)
  fixture.fileManager.createFile(
    atPath: target.appendingPathComponent("user.txt").path, contents: nil)

  fixture.coordinator.routeMove(target: target)

  #expect(fixture.coordinator.confirmation == nil)
  if case .error = fixture.coordinator.notice {
  } else {
    Issue.record("expected error notice, got \(String(describing: fixture.coordinator.notice))")
  }
}

@MainActor
@Test func adoptGachaRootPublishesAdoptConfirmation() throws {
  let fixture = makeCoordinatorFixture()
  try fixture.populateCurrentRoot()
  let target = fixture.scratchURL.appendingPathComponent("existing-gacha", isDirectory: true)
  try fixture.fileManager.createDirectory(at: target, withIntermediateDirectories: true)
  fixture.fileManager.createFile(
    atPath: target.appendingPathComponent(AppMetadata.storageRootMarkerName).path,
    contents: nil)

  fixture.coordinator.routeAdopt(target: target)

  let confirmation = try #require(fixture.coordinator.confirmation)
  #expect(confirmation.intent == .adopt)
}

@MainActor
@Test func adoptNonGachaTargetPublishesErrorNotice() throws {
  let fixture = makeCoordinatorFixture()
  let target = fixture.scratchURL.appendingPathComponent("not-gacha", isDirectory: true)
  try fixture.fileManager.createDirectory(at: target, withIntermediateDirectories: true)

  fixture.coordinator.routeAdopt(target: target)

  #expect(fixture.coordinator.confirmation == nil)
  if case .error = fixture.coordinator.notice {
  } else {
    Issue.record("expected error notice, got \(String(describing: fixture.coordinator.notice))")
  }
}

@MainActor
private final class StorageRelocationCoordinatorFixture {
  let fileManager = FileManager.default
  let scratchURL: URL
  let originalRootURL: URL
  let settingsStore: SettingsStore
  let coordinator: StorageRelocationCoordinator

  init() {
    scratchURL = URL(
      fileURLWithPath:
        "/tmp/agents/GachaTests/StorageRelocationCoordinator/\(UUID().uuidString)")
    originalRootURL = scratchURL.appendingPathComponent("Root", isDirectory: true)

    let suiteName = "GachaTests.StorageRelocationCoordinator.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    settingsStore = SettingsStore(defaults: defaults, defaultUserStorageURL: originalRootURL)
    coordinator = StorageRelocationCoordinator(
      relocator: StorageRelocator(settingsStore: settingsStore, fileManager: fileManager),
      settingsStore: settingsStore,
      cardCount: { 0 },
      relaunch: {})
  }

  func populateCurrentRoot() throws {
    let markerURL = originalRootURL.appendingPathComponent(AppMetadata.storageRootMarkerName)
    let memoryURL =
      originalRootURL
      .appendingPathComponent("memory")
      .appendingPathComponent("Uncategorized")
    try fileManager.createDirectory(at: memoryURL, withIntermediateDirectories: true)
    fileManager.createFile(atPath: markerURL.path, contents: nil)
  }
}

@MainActor
private func makeCoordinatorFixture() -> StorageRelocationCoordinatorFixture {
  StorageRelocationCoordinatorFixture()
}
