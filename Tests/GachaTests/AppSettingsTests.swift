import Foundation
import Testing

@testable import Gacha

@Test func appSettingsDefaultsUseDefaultValues() {
  let defaultUserStorageURL = URL(fileURLWithPath: "/tmp/GachaTests/Documents/Gacha")
  let settings = AppSettings.defaults(userStorageURL: defaultUserStorageURL)

  #expect(settings.userStorageURL == defaultUserStorageURL)
  #expect(settings.launchAtLoginEnabled)
  #expect(settings.knowledgeAutoCollapseSeconds == 30)
}

@Test func settingsStoreReadsRegisteredDefaults() {
  let defaultUserStorageURL = URL(fileURLWithPath: "/tmp/GachaTests/Documents/Gacha")
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults, defaultUserStorageURL: defaultUserStorageURL)

  #expect(store.settings == AppSettings.defaults(userStorageURL: defaultUserStorageURL))
}

@Test func settingsStorePersistsUserStorageURL() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)
  let userStorageURL = URL(fileURLWithPath: "/tmp/GachaTests/Custom Storage", isDirectory: true)

  store.userStorageURL = userStorageURL

  let reloadedStore = SettingsStore(defaults: defaults)

  #expect(reloadedStore.userStorageURL == userStorageURL)
}

@Test func settingsStorePersistsKnowledgeAutoCollapseSeconds() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.knowledgeAutoCollapseSeconds = 45

  let reloadedStore = SettingsStore(defaults: defaults)

  #expect(reloadedStore.knowledgeAutoCollapseSeconds == 45)
}

@Test func settingsStorePersistsLaunchAtLoginEnabled() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.launchAtLoginEnabled = false

  let reloadedStore = SettingsStore(defaults: defaults)

  #expect(!reloadedStore.launchAtLoginEnabled)
}

@Test func settingsStorePersistsTypedSettings() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)
  let userStorageURL = URL(fileURLWithPath: "/tmp/GachaTests/Typed Storage", isDirectory: true)

  store.settings = AppSettings(
    userStorageURL: userStorageURL,
    launchAtLoginEnabled: false,
    knowledgeAutoCollapseSeconds: 60)

  #expect(store.settings.userStorageURL == userStorageURL)
  #expect(!store.settings.launchAtLoginEnabled)
  #expect(store.settings.knowledgeAutoCollapseSeconds == 60)
}

@Test func settingsStoreNormalizesKnowledgeAutoCollapseSeconds() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.knowledgeAutoCollapseSeconds = 3
  #expect(store.knowledgeAutoCollapseSeconds == 5)

  store.knowledgeAutoCollapseSeconds = 42
  #expect(store.knowledgeAutoCollapseSeconds == 40)

  store.knowledgeAutoCollapseSeconds = 300
  #expect(store.knowledgeAutoCollapseSeconds == 120)
}

private func makeTestDefaults() -> UserDefaults {
  let suiteName = "GachaTests.SettingsStore.\(UUID().uuidString)"
  let defaults = UserDefaults(suiteName: suiteName)!
  defaults.removePersistentDomain(forName: suiteName)
  return defaults
}
