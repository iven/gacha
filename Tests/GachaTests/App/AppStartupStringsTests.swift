import Testing

@testable import Gacha

@Test func appStartupStringsResolveFromLocalizationResources() {
  #expect(AppStartupStrings.failureTitle != "startup.failure.title")
  #expect(AppStartupStrings.failureQuit != "startup.failure.quit")
  #expect(AppStartupStrings.failureMessage(errorDescription: "Example").contains("Example"))
}

@Test func appStartupStringsResolveSimplifiedChinesePreferences() {
  let preferences = ["zh-Hans-CN", "en-CN"]

  #expect(AppStrings.localized("startup.failure.title", preferences: preferences) == "Gacha 无法启动")
  #expect(AppStrings.localized("startup.failure.quit", preferences: preferences) == "退出")
  #expect(
    AppStrings.localized("startup.failure.message", preferences: preferences)
      .contains("错误信息"))
}
