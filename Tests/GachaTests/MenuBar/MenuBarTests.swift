import Testing

@testable import Gacha

@MainActor
@Test func menuBarViewModelForwardsTogglePause() {
  let viewModel = MenuBarViewModel()
  var received: [Bool] = []
  viewModel.onTogglePause = { received.append($0) }

  viewModel.onTogglePause?(true)
  viewModel.onTogglePause?(false)

  #expect(received == [true, false])
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
