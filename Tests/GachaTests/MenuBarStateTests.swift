import Testing

@testable import Gacha

@Test func menuBarStateUsesPauseOrResumeTitle() {
  var state = MenuBarState()

  #expect(state.pauseDisplayTitle == MenuBarStrings.pauseDisplay)

  state.isPaused = true

  #expect(state.pauseDisplayTitle == MenuBarStrings.resumeDisplay)
}

@Test func menuBarStringsResolveFromLocalizationResources() {
  #expect(MenuBarStrings.cards != "menu.cards")
  #expect(MenuBarStrings.pauseDisplay != "menu.pauseDisplay")
  #expect(MenuBarStrings.resumeDisplay != "menu.resumeDisplay")
  #expect(MenuBarStrings.settings != "menu.settings")
  #expect(MenuBarStrings.quit != "menu.quit")
}

@Test func menuBarStringsResolveSimplifiedChinesePreferences() {
  let preferences = ["zh-Hans-CN", "en-CN"]

  #expect(AppStrings.localized("menu.cards", preferences: preferences) != "menu.cards")
  #expect(
    AppStrings.localized("menu.pauseDisplay", preferences: preferences) != "menu.pauseDisplay")
}
