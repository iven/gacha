import Testing

@testable import Gacha

@Test func menuBarStateUsesPauseOrResumeTitle() {
  var state = MenuBarState()

  #expect(state.pauseDisplayTitle == MenuBarStrings.pauseDisplay)

  state.isPaused = true

  #expect(state.pauseDisplayTitle == MenuBarStrings.resumeDisplay)
}

@Test func menuBarStringsResolveFromLocalizationResources() {
  #expect(MenuBarStrings.newCard != "menu.newCard")
  #expect(MenuBarStrings.pauseDisplay != "menu.pauseDisplay")
  #expect(MenuBarStrings.resumeDisplay != "menu.resumeDisplay")
  #expect(MenuBarStrings.settings != "menu.settings")
  #expect(MenuBarStrings.quit != "menu.quit")
}

@Test func menuBarStringsResolveSimplifiedChinesePreferences() {
  let preferences = ["zh-Hans-CN", "en-CN"]

  #expect(MenuBarStrings.localized("menu.newCard", preferences: preferences) == "新建卡片...")
  #expect(MenuBarStrings.localized("menu.pauseDisplay", preferences: preferences) == "暂停显示")
  #expect(MenuBarStrings.localized("menu.resumeDisplay", preferences: preferences) == "恢复显示")
  #expect(MenuBarStrings.localized("menu.settings", preferences: preferences) == "设置...")
  #expect(MenuBarStrings.localized("menu.quit", preferences: preferences) == "退出 Gacha")
}
