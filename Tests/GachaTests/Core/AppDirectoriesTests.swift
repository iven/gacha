import Foundation
import Testing

@testable import Gacha

@Test func appDirectoriesDescribeExpectedDirectoryTree() {
  let testRootURL = URL(fileURLWithPath: "/tmp/GachaTests")
  let directories = AppDirectories(
    applicationSupportURL: testRootURL.appendingPathComponent("Application Support"),
    userStorageURL: testRootURL.appendingPathComponent("Documents"))

  #expect(directories.applicationSupportURL.path == "/tmp/GachaTests/Application Support")
  #expect(directories.indexDatabaseURL.path == "/tmp/GachaTests/Application Support/index.db")
  #expect(directories.userStorageURL.path == "/tmp/GachaTests/Documents")
  #expect(directories.memoryURL.lastPathComponent == "memory")
  #expect(directories.defaultMemoryCategoryURL.lastPathComponent == "Uncategorized")
  #expect(directories.storageRootMarkerURL.path == "/tmp/GachaTests/Documents/.gacha")
}

@Test func appDirectoriesUseSettingsStorageLocation() {
  let testRootURL = URL(fileURLWithPath: "/tmp/GachaTests")
  let userStorageURL = testRootURL.appendingPathComponent("Custom Storage")
  let settingsStore = SettingsStore(
    defaults: makeTestDefaults(),
    defaultUserStorageURL: userStorageURL)
  let directories = AppDirectories(
    settingsStore: settingsStore,
    fileManager: .default)

  #expect(directories.userStorageURL == userStorageURL)
  #expect(directories.memoryURL.path == "/tmp/GachaTests/Custom Storage/memory")
}

private func makeTestDefaults() -> UserDefaults {
  let suiteName = "GachaTests.AppDirectories.\(UUID().uuidString)"
  let defaults = UserDefaults(suiteName: suiteName)!
  defaults.removePersistentDomain(forName: suiteName)
  return defaults
}
