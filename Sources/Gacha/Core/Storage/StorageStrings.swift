import Foundation

enum StorageStrings {
  static let cancel = AppStrings.localized("storage.relocate.cancel")
  static let errorTitle = AppStrings.localized("storage.relocate.error.title")
  static let errorDismiss = AppStrings.localized("storage.relocate.error.dismiss")
  static let failureTitle = AppStrings.localized("storage.relocate.failure.title")
  static let failureDismiss = AppStrings.localized("storage.relocate.failure.dismiss")

  static func moveTitle(targetName: String) -> String {
    String(format: AppStrings.localized("storage.relocate.move.title"), targetName)
  }

  static func moveMessage(cardCount: Int) -> String {
    String(format: AppStrings.localized("storage.relocate.move.message"), cardCount)
  }

  static let moveConfirm = AppStrings.localized("storage.relocate.move.confirm")

  static func adoptTitle(targetName: String) -> String {
    String(format: AppStrings.localized("storage.relocate.adopt.title"), targetName)
  }

  static let adoptMessage = AppStrings.localized("storage.relocate.adopt.message")
  static let adoptConfirm = AppStrings.localized("storage.relocate.adopt.confirm")

  static let successTitle = AppStrings.localized("storage.relocate.success.title")
  static let successRelaunch = AppStrings.localized("storage.relocate.success.relaunch")

  static func successMessage(newPath: String) -> String {
    String(format: AppStrings.localized("storage.relocate.success.message"), newPath)
  }
}
