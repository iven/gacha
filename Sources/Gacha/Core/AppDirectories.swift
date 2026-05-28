import Foundation

struct AppDirectories {
  let applicationSupportURL: URL
  let userStorageURL: URL
  let indexDatabaseURL: URL
  let memoryURL: URL
  let defaultMemoryCategoryURL: URL
  let storageRootMarkerURL: URL

  init(settingsStore: SettingsStore, fileManager: FileManager = .default) {
    self.init(
      applicationSupportURL: fileManager.urls(
        for: .applicationSupportDirectory, in: .userDomainMask
      )[0].appendingPathComponent(AppMetadata.applicationSupportDirectoryName, isDirectory: true),
      userStorageURL: settingsStore.userStorageURL)
  }

  init(applicationSupportURL: URL, userStorageURL: URL) {
    self.applicationSupportURL = applicationSupportURL
    self.userStorageURL = userStorageURL
    indexDatabaseURL = applicationSupportURL.appendingPathComponent("index.db")
    memoryURL = userStorageURL.appendingPathComponent(
      AppMetadata.memoryDirectoryName,
      isDirectory: true)
    defaultMemoryCategoryURL = memoryURL.appendingPathComponent(
      AppMetadata.defaultCategoryDirectoryName,
      isDirectory: true)
    storageRootMarkerURL = userStorageURL.appendingPathComponent(
      AppMetadata.storageRootMarkerName,
      isDirectory: false)
  }

  /// Ensures the application's storage roots exist:
  /// - Application Support directory (for the SQLite index, logs, etc.)
  /// - User storage root (carries the `.gacha` marker so it can later be
  ///   identified as a Gacha-managed directory during relocation)
  /// Subdomains (e.g. `memory/`) are responsible for creating their own
  /// subdirectories beneath `userStorageURL`.
  func prepareRoot(fileManager: FileManager = .default) throws {
    try fileManager.createDirectory(
      at: applicationSupportURL,
      withIntermediateDirectories: true)
    try fileManager.createDirectory(
      at: userStorageURL,
      withIntermediateDirectories: true)
    if !fileManager.fileExists(atPath: storageRootMarkerURL.path) {
      fileManager.createFile(atPath: storageRootMarkerURL.path, contents: nil)
    }
  }
}
