import Foundation

enum AppStartupStrings {
  static let failureTitle = AppStrings.localized("startup.failure.title")
  static let failureQuit = AppStrings.localized("startup.failure.quit")

  static func failureMessage(errorDescription: String) -> String {
    String(
      format: AppStrings.localized("startup.failure.message"),
      errorDescription)
  }
}
