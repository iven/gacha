import Foundation

enum AppAboutStrings {
  static let menuTitle = AppStrings.localized("app.about.menu")
  static let slogan = AppStrings.localized("app.about.slogan")
  static let copyright = AppStrings.localized("app.about.copyright")

  static func version(_ version: String) -> String {
    String(format: AppStrings.localized("app.about.version"), version)
  }

  static var credits: String {
    "\(slogan)\n\(copyright)"
  }
}
