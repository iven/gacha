import Foundation
import Testing

@testable import Gacha

@Test func appSettingsDefaultsUseDefaultValues() {
  let defaultUserStorageURL = URL(fileURLWithPath: "/tmp/GachaTests/Documents/Gacha")
  let settings = AppSettings.defaults(userStorageURL: defaultUserStorageURL)

  #expect(settings.userStorageURL == defaultUserStorageURL)
  #expect(settings.launchAtLoginEnabled)
  #expect(settings.memoryAutoCollapseSeconds == 1)
  #expect(settings.skipCountdownOnAnotherWindow)
  #expect(settings.showKeyboardHints)
  #expect(settings.fullScreenSuppressionEnabled)
  #expect(settings.screenSharingSuppressionEnabled)
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
    memoryAutoCollapseSeconds: 60,
    skipCountdownOnAnotherWindow: false,
    showKeyboardHints: false,
    fullScreenSuppressionEnabled: false,
    screenSharingSuppressionEnabled: false)

  #expect(store.settings.userStorageURL == userStorageURL)
  #expect(!store.settings.launchAtLoginEnabled)
  #expect(store.settings.memoryAutoCollapseSeconds == 60)
  #expect(!store.settings.skipCountdownOnAnotherWindow)
  #expect(!store.settings.showKeyboardHints)
  #expect(!store.settings.fullScreenSuppressionEnabled)
  #expect(!store.settings.screenSharingSuppressionEnabled)
}

@Test func settingsStorePersistsSkipCountdownOnAnotherWindow() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.skipCountdownOnAnotherWindow = false

  let reloadedStore = SettingsStore(defaults: defaults)

  #expect(!reloadedStore.skipCountdownOnAnotherWindow)
}

@Test func settingsStorePersistsShowKeyboardHints() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.showKeyboardHints = false

  let reloadedStore = SettingsStore(defaults: defaults)

  #expect(!reloadedStore.showKeyboardHints)
}

@Test func settingsStorePersistsFullScreenSuppressionEnabled() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.fullScreenSuppressionEnabled = false

  let reloadedStore = SettingsStore(defaults: defaults)

  #expect(!reloadedStore.fullScreenSuppressionEnabled)
}

@Test func settingsStorePersistsScreenSharingSuppressionEnabled() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.screenSharingSuppressionEnabled = false

  let reloadedStore = SettingsStore(defaults: defaults)

  #expect(!reloadedStore.screenSharingSuppressionEnabled)
}

@Test func settingsStoreNormalizesMemoryAutoCollapseSeconds() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.memoryAutoCollapseSeconds = -1
  #expect(store.memoryAutoCollapseSeconds == 0)

  store.memoryAutoCollapseSeconds = 0
  #expect(store.memoryAutoCollapseSeconds == 0)

  store.memoryAutoCollapseSeconds = 7.4
  #expect(store.memoryAutoCollapseSeconds == 7)

  store.memoryAutoCollapseSeconds = 7.6
  #expect(store.memoryAutoCollapseSeconds == 8)

  store.memoryAutoCollapseSeconds = 300
  #expect(store.memoryAutoCollapseSeconds == 60)
}

private func makeTestDefaults() -> UserDefaults {
  let suiteName = "GachaTests.SettingsStore.\(UUID().uuidString)"
  let defaults = UserDefaults(suiteName: suiteName)!
  defaults.removePersistentDomain(forName: suiteName)
  return defaults
}
