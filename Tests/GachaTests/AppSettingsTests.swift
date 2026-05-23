import Foundation
import Testing

@testable import Gacha

@Test func appSettingsDefaultsUseDefaultValues() {
  let defaultUserStorageURL = URL(fileURLWithPath: "/tmp/GachaTests/Documents/Gacha")
  let settings = AppSettings.defaults(userStorageURL: defaultUserStorageURL)

  #expect(settings.userStorageURL == defaultUserStorageURL)
  #expect(settings.launchAtLoginEnabled)
  #expect(settings.memoryAutoCollapseSeconds == 30)
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

@Test func settingsStorePersistsMemoryAutoCollapseSeconds() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.memoryAutoCollapseSeconds = 45

  let reloadedStore = SettingsStore(defaults: defaults)

  #expect(reloadedStore.memoryAutoCollapseSeconds == 45)
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
    memoryAutoCollapseSeconds: 60)

  #expect(store.settings.userStorageURL == userStorageURL)
  #expect(!store.settings.launchAtLoginEnabled)
  #expect(store.settings.memoryAutoCollapseSeconds == 60)
}

@Test func settingsStoreNormalizesMemoryAutoCollapseSeconds() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.memoryAutoCollapseSeconds = 3
  #expect(store.memoryAutoCollapseSeconds == 5)

  store.memoryAutoCollapseSeconds = 42
  #expect(store.memoryAutoCollapseSeconds == 40)

  store.memoryAutoCollapseSeconds = 300
  #expect(store.memoryAutoCollapseSeconds == 120)
}

private func makeTestDefaults() -> UserDefaults {
  let suiteName = "GachaTests.SettingsStore.\(UUID().uuidString)"
  let defaults = UserDefaults(suiteName: suiteName)!
  defaults.removePersistentDomain(forName: suiteName)
  return defaults
}
