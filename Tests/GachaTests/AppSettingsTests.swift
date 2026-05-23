import Foundation
import Testing

@testable import Gacha

@Test func appSettingsDefaultsUseKnowledgeAutoCollapseTimeout() {
  #expect(AppSettings.defaults.knowledgeAutoCollapseSeconds == 30)
}

@Test func settingsStoreReadsRegisteredDefaults() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  #expect(store.settings == AppSettings.defaults)
}

@Test func settingsStorePersistsKnowledgeAutoCollapseSeconds() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.knowledgeAutoCollapseSeconds = 45

  let reloadedStore = SettingsStore(defaults: defaults)

  #expect(reloadedStore.knowledgeAutoCollapseSeconds == 45)
}

@Test func settingsStorePersistsTypedSettings() {
  let defaults = makeTestDefaults()
  let store = SettingsStore(defaults: defaults)

  store.settings = AppSettings(knowledgeAutoCollapseSeconds: 60)

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
