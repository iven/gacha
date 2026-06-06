import Foundation
import Testing

@testable import Gacha

@Test func appSettingsDefaultsUseDefaultValues() {
  let defaultUserStorageURL = URL(fileURLWithPath: "/tmp/GachaTests/Documents/Gacha")
  let settings = AppSettings.defaults(userStorageURL: defaultUserStorageURL)

  #expect(settings.userStorageURL == defaultUserStorageURL)
  #expect(settings.launchAtLoginEnabled)
  #expect(settings.memoryCardAutoCollapseSeconds == 1)
  #expect(settings.noticeAutoCollapseSeconds == 1)
  #expect(settings.idleReminderAnimationSeconds == 30 * 60)
  #expect(settings.skipAutoCollapseOnAnotherWindow)
  #expect(settings.showKeyboardHints)
  #expect(settings.fullScreenSuppressionEnabled)
  #expect(settings.screenSharingSuppressionEnabled)
  #expect(settings.focusModeSuppressionEnabled)
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

@Test func settingsStorePersistsMemoryCardAutoCollapseSeconds() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.memoryCardAutoCollapseSeconds = 45

  let reloadedStore = SettingsStore(defaults: defaults)

  #expect(reloadedStore.memoryCardAutoCollapseSeconds == 45)
}

@Test func settingsStorePersistsNoticeAutoCollapseSeconds() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.noticeAutoCollapseSeconds = 7

  let reloadedStore = SettingsStore(defaults: defaults)

  #expect(reloadedStore.noticeAutoCollapseSeconds == 7)
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
    memoryCardAutoCollapseSeconds: 60,
    noticeAutoCollapseSeconds: 8,
    idleReminderAnimationSeconds: 15 * 60,
    skipAutoCollapseOnAnotherWindow: false,
    showKeyboardHints: false,
    fullScreenSuppressionEnabled: false,
    screenSharingSuppressionEnabled: false,
    focusModeSuppressionEnabled: false,
    mcpEnabled: true,
    mcpPort: 8888)

  #expect(store.settings.userStorageURL == userStorageURL)
  #expect(!store.settings.launchAtLoginEnabled)
  #expect(store.settings.memoryCardAutoCollapseSeconds == 60)
  #expect(store.settings.noticeAutoCollapseSeconds == 8)
  #expect(store.settings.idleReminderAnimationSeconds == 15 * 60)
  #expect(!store.settings.skipAutoCollapseOnAnotherWindow)
  #expect(!store.settings.showKeyboardHints)
  #expect(!store.settings.fullScreenSuppressionEnabled)
  #expect(!store.settings.screenSharingSuppressionEnabled)
  #expect(!store.settings.focusModeSuppressionEnabled)
  #expect(store.settings.mcpEnabled)
  #expect(store.settings.mcpPort == 8888)
}

@Test func settingsStorePersistsSkipCountdownOnAnotherWindow() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.skipAutoCollapseOnAnotherWindow = false

  let reloadedStore = SettingsStore(defaults: defaults)

  #expect(!reloadedStore.skipAutoCollapseOnAnotherWindow)
}

@Test func settingsStorePersistsShowKeyboardHints() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.showKeyboardHints = false

  let reloadedStore = SettingsStore(defaults: defaults)

  #expect(!reloadedStore.showKeyboardHints)
}

@Test func settingsStorePersistsIdleReminderAnimationSeconds() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.idleReminderAnimationSeconds = 15 * 60

  let reloadedStore = SettingsStore(defaults: defaults)

  #expect(reloadedStore.idleReminderAnimationSeconds == 15 * 60)
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

@Test func settingsStorePersistsFocusModeSuppressionEnabled() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.focusModeSuppressionEnabled = false

  let reloadedStore = SettingsStore(defaults: defaults)

  #expect(!reloadedStore.focusModeSuppressionEnabled)
}

@Test func settingsStoreNormalizesMemoryCardAutoCollapseSeconds() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.memoryCardAutoCollapseSeconds = -1
  #expect(store.memoryCardAutoCollapseSeconds == 0)

  store.memoryCardAutoCollapseSeconds = 0
  #expect(store.memoryCardAutoCollapseSeconds == 0)

  store.memoryCardAutoCollapseSeconds = 7.4
  #expect(store.memoryCardAutoCollapseSeconds == 7)

  store.memoryCardAutoCollapseSeconds = 7.6
  #expect(store.memoryCardAutoCollapseSeconds == 8)

  store.memoryCardAutoCollapseSeconds = 300
  #expect(store.memoryCardAutoCollapseSeconds == 60)
}

@Test func settingsStoreNormalizesNoticeAutoCollapseSeconds() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.noticeAutoCollapseSeconds = -1
  #expect(store.noticeAutoCollapseSeconds == 1)

  store.noticeAutoCollapseSeconds = 0
  #expect(store.noticeAutoCollapseSeconds == 1)

  store.noticeAutoCollapseSeconds = 7.4
  #expect(store.noticeAutoCollapseSeconds == 7)

  store.noticeAutoCollapseSeconds = 7.6
  #expect(store.noticeAutoCollapseSeconds == 8)

  store.noticeAutoCollapseSeconds = 300
  #expect(store.noticeAutoCollapseSeconds == 10)
}

@Test func settingsStoreNormalizesIdleReminderAnimationSeconds() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.idleReminderAnimationSeconds = -1
  #expect(store.idleReminderAnimationSeconds == 0)

  store.idleReminderAnimationSeconds = 89
  #expect(store.idleReminderAnimationSeconds == 60)

  store.idleReminderAnimationSeconds = 91
  #expect(store.idleReminderAnimationSeconds == 120)

  store.idleReminderAnimationSeconds = 999 * 60
  #expect(store.idleReminderAnimationSeconds == 180 * 60)
}

private func makeTestDefaults() -> UserDefaults {
  let suiteName = "GachaTests.SettingsStore.\(UUID().uuidString)"
  let defaults = UserDefaults(suiteName: suiteName)!
  defaults.removePersistentDomain(forName: suiteName)
  return defaults
}
