import Foundation

struct AppDirectories {
  let applicationSupportURL: URL
  let userStorageURL: URL
  let knowledgeCardsURL: URL
  let defaultKnowledgeCategoryURL: URL

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
    knowledgeCardsURL = userStorageURL.appendingPathComponent(
      AppMetadata.knowledgeCardsDirectoryName,
      isDirectory: true)
    defaultKnowledgeCategoryURL = knowledgeCardsURL.appendingPathComponent(
      AppMetadata.defaultCategoryDirectoryName,
      isDirectory: true)
  }
}
