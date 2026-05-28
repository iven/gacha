import Foundation

struct StorageRelocator {
  let settingsStore: SettingsStore
  let fileManager: FileManager

  init(settingsStore: SettingsStore, fileManager: FileManager = .default) {
    self.settingsStore = settingsStore
    self.fileManager = fileManager
  }

  func inspect(target: URL) throws -> StorageTargetState {
    let resolvedTarget = target.resolvingSymlinksInPath().standardizedFileURL
    let resolvedCurrent =
      settingsStore.userStorageURL.resolvingSymlinksInPath().standardizedFileURL
    if resolvedTarget == resolvedCurrent {
      throw StorageRelocationError.targetIsCurrentLocation
    }

    var isDirectory: ObjCBool = false
    let exists = fileManager.fileExists(atPath: target.path, isDirectory: &isDirectory)
    if !exists {
      return .fresh
    }
    if !isDirectory.boolValue {
      throw StorageRelocationError.targetIsOccupied
    }

    let markerURL = target.appendingPathComponent(
      AppMetadata.storageRootMarkerName, isDirectory: false)
    if fileManager.fileExists(atPath: markerURL.path) {
      return .adoptable
    }

    do {
      let entries = try fileManager.contentsOfDirectory(
        at: target, includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles])
      return entries.isEmpty ? .fresh : .occupied
    } catch {
      throw StorageRelocationError.targetUnreadable(error.localizedDescription)
    }
  }

  /// Moves the current storage root's contents into `target`. The current root
  /// must contain the marker file; the caller is responsible for verifying via
  /// `inspect(target:)` that `target` is `.fresh` (i.e. nonexistent or empty).
  /// Updates `userStoragePath` on success.
  func move(to target: URL) throws {
    let source = settingsStore.userStorageURL
    let resolvedSource = source.resolvingSymlinksInPath().standardizedFileURL
    let resolvedTarget = target.resolvingSymlinksInPath().standardizedFileURL
    if resolvedSource == resolvedTarget {
      throw StorageRelocationError.targetIsCurrentLocation
    }

    if fileManager.fileExists(atPath: target.path) {
      let entries = try fileManager.contentsOfDirectory(
        at: target, includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles])
      guard entries.isEmpty else {
        throw StorageRelocationError.targetIsOccupied
      }
      try fileManager.removeItem(at: target)
    }
    try fileManager.createDirectory(
      at: target.deletingLastPathComponent(),
      withIntermediateDirectories: true)
    try fileManager.moveItem(at: source, to: target)
    settingsStore.userStorageURL = target
  }

  /// Repoints the storage root at an existing Gacha root (one carrying the
  /// marker file). The current source root is left untouched. Updates
  /// `userStoragePath` on success.
  func adopt(target: URL) throws {
    let markerURL = target.appendingPathComponent(
      AppMetadata.storageRootMarkerName, isDirectory: false)
    guard fileManager.fileExists(atPath: markerURL.path) else {
      throw StorageRelocationError.targetMissingMarker
    }
    settingsStore.userStorageURL = target
  }
}
