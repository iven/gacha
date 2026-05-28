import Foundation
import Testing

@testable import Gacha

@Test func inspectReturnsFreshForNonexistentTarget() throws {
  let fixture = makeFixture()
  let target = fixture.scratchURL.appendingPathComponent("never-existed", isDirectory: true)

  #expect(try fixture.relocator.inspect(target: target) == .fresh)
}

@Test func inspectReturnsFreshForEmptyDirectory() throws {
  let fixture = makeFixture()
  let target = fixture.scratchURL.appendingPathComponent("empty", isDirectory: true)
  try fixture.fileManager.createDirectory(at: target, withIntermediateDirectories: true)

  #expect(try fixture.relocator.inspect(target: target) == .fresh)
}

@Test func inspectReturnsFreshWhenOnlyHiddenFilesPresent() throws {
  let fixture = makeFixture()
  let target = fixture.scratchURL.appendingPathComponent("hidden-only", isDirectory: true)
  try fixture.fileManager.createDirectory(at: target, withIntermediateDirectories: true)
  fixture.fileManager.createFile(
    atPath: target.appendingPathComponent(".DS_Store").path, contents: nil)

  #expect(try fixture.relocator.inspect(target: target) == .fresh)
}

@Test func inspectReturnsAdoptableWhenMarkerPresent() throws {
  let fixture = makeFixture()
  let target = fixture.scratchURL.appendingPathComponent("adoptable", isDirectory: true)
  try fixture.fileManager.createDirectory(at: target, withIntermediateDirectories: true)
  fixture.fileManager.createFile(
    atPath: target.appendingPathComponent(AppMetadata.storageRootMarkerName).path,
    contents: nil)
  // Marker plus arbitrary content: still adoptable.
  fixture.fileManager.createFile(
    atPath: target.appendingPathComponent("arbitrary.txt").path, contents: nil)

  #expect(try fixture.relocator.inspect(target: target) == .adoptable)
}

@Test func inspectReturnsOccupiedForNonGachaContent() throws {
  let fixture = makeFixture()
  let target = fixture.scratchURL.appendingPathComponent("occupied", isDirectory: true)
  try fixture.fileManager.createDirectory(at: target, withIntermediateDirectories: true)
  fixture.fileManager.createFile(
    atPath: target.appendingPathComponent("user-file.txt").path, contents: nil)

  #expect(try fixture.relocator.inspect(target: target) == .occupied)
}

@Test func inspectThrowsWhenTargetEqualsCurrentLocation() {
  let fixture = makeFixture()
  let target = fixture.settingsStore.userStorageURL

  #expect(throws: StorageRelocationError.targetIsCurrentLocation) {
    try fixture.relocator.inspect(target: target)
  }
}

@Test func inspectThrowsWhenTargetIsRegularFile() throws {
  let fixture = makeFixture()
  try fixture.fileManager.createDirectory(at: fixture.scratchURL, withIntermediateDirectories: true)
  let target = fixture.scratchURL.appendingPathComponent("not-a-dir.txt")
  fixture.fileManager.createFile(atPath: target.path, contents: nil)

  #expect(throws: StorageRelocationError.targetIsOccupied) {
    try fixture.relocator.inspect(target: target)
  }
}

@Test func moveRelocatesEntireRootAndUpdatesSettings() throws {
  let fixture = makeFixture()
  try fixture.populateCurrentRoot()
  let target = fixture.scratchURL.appendingPathComponent("new-root", isDirectory: true)

  try fixture.relocator.move(to: target)

  #expect(!fixture.fileManager.fileExists(atPath: fixture.originalRootURL.path))
  #expect(
    fixture.fileManager.fileExists(
      atPath: target.appendingPathComponent(AppMetadata.storageRootMarkerName).path))
  #expect(
    fixture.fileManager.fileExists(
      atPath: target.appendingPathComponent("memory").path))
  #expect(fixture.settingsStore.userStorageURL.standardizedFileURL == target.standardizedFileURL)
}

@Test func moveSucceedsWhenTargetIsExistingEmptyDirectory() throws {
  let fixture = makeFixture()
  try fixture.populateCurrentRoot()
  let target = fixture.scratchURL.appendingPathComponent("preexisting-empty", isDirectory: true)
  try fixture.fileManager.createDirectory(at: target, withIntermediateDirectories: true)

  try fixture.relocator.move(to: target)

  #expect(
    fixture.fileManager.fileExists(
      atPath: target.appendingPathComponent(AppMetadata.storageRootMarkerName).path))
}

@Test func moveThrowsWhenTargetExistsAndNonEmpty() throws {
  let fixture = makeFixture()
  try fixture.populateCurrentRoot()
  let target = fixture.scratchURL.appendingPathComponent("preexisting-occupied", isDirectory: true)
  try fixture.fileManager.createDirectory(at: target, withIntermediateDirectories: true)
  fixture.fileManager.createFile(
    atPath: target.appendingPathComponent("user-file.txt").path, contents: nil)

  #expect(throws: StorageRelocationError.targetIsOccupied) {
    try fixture.relocator.move(to: target)
  }
  // Source untouched on failure.
  #expect(
    fixture.fileManager.fileExists(
      atPath: fixture.originalRootURL.appendingPathComponent(AppMetadata.storageRootMarkerName).path
    ))
}

@Test func adoptRepointsSettingsAndLeavesSourceUntouched() throws {
  let fixture = makeFixture()
  try fixture.populateCurrentRoot()
  let target = fixture.scratchURL.appendingPathComponent("existing-gacha", isDirectory: true)
  try fixture.fileManager.createDirectory(at: target, withIntermediateDirectories: true)
  fixture.fileManager.createFile(
    atPath: target.appendingPathComponent(AppMetadata.storageRootMarkerName).path,
    contents: nil)

  try fixture.relocator.adopt(target: target)

  #expect(fixture.settingsStore.userStorageURL.standardizedFileURL == target.standardizedFileURL)
  #expect(
    fixture.fileManager.fileExists(
      atPath: fixture.originalRootURL.appendingPathComponent(AppMetadata.storageRootMarkerName).path
    ))
}

@Test func adoptThrowsWhenTargetMissingMarker() throws {
  let fixture = makeFixture()
  let target = fixture.scratchURL.appendingPathComponent("not-gacha", isDirectory: true)
  try fixture.fileManager.createDirectory(at: target, withIntermediateDirectories: true)

  #expect(throws: StorageRelocationError.targetMissingMarker) {
    try fixture.relocator.adopt(target: target)
  }
}

@Test func prepareRootIsIdempotentAndPreservesMarker() throws {
  let fixture = makeFixture()
  let directories = AppDirectories(
    applicationSupportURL: fixture.scratchURL.appendingPathComponent("AppSupport"),
    userStorageURL: fixture.scratchURL.appendingPathComponent("Root"))

  try directories.prepareRoot(fileManager: fixture.fileManager)
  let markerData = "sentinel".data(using: .utf8)!
  try markerData.write(to: directories.storageRootMarkerURL)
  try directories.prepareRoot(fileManager: fixture.fileManager)

  let preserved = try Data(contentsOf: directories.storageRootMarkerURL)
  #expect(preserved == markerData)
}

private final class StorageRelocatorFixture {
  let fileManager = FileManager.default
  let scratchURL: URL
  let originalRootURL: URL
  let settingsStore: SettingsStore
  let relocator: StorageRelocator

  init() {
    scratchURL = URL(
      fileURLWithPath:
        "/tmp/agents/GachaTests/StorageRelocator/\(UUID().uuidString)")
    originalRootURL = scratchURL.appendingPathComponent("Root", isDirectory: true)

    let suiteName = "GachaTests.StorageRelocator.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    settingsStore = SettingsStore(defaults: defaults, defaultUserStorageURL: originalRootURL)
    relocator = StorageRelocator(settingsStore: settingsStore, fileManager: fileManager)
  }

  /// Lays out a realistic source root: marker + memory/Uncategorized/.
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

private func makeFixture() -> StorageRelocatorFixture {
  StorageRelocatorFixture()
}
