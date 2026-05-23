import Foundation

struct AppDirectories {
  let applicationSupportURL: URL
  let userStorageURL: URL
  let indexDatabaseURL: URL
  let memoryURL: URL
  let defaultMemoryCategoryURL: URL

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
  }
}
