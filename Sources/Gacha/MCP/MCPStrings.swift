import Foundation

enum MCPStrings {
  // MARK: - Tool descriptions

  static let listCardsDescription = AppStrings.localized("mcp.tool.listCards.description")
  static let listCardsCategoryParam = AppStrings.localized("mcp.tool.listCards.category")
  static let createCardDescription = AppStrings.localized("mcp.tool.createCard.description")
  static let createCardBodyParam = AppStrings.localized("mcp.tool.createCard.body")
  static let createCardCategoryParam = AppStrings.localized("mcp.tool.createCard.category")
  static let updateCardDescription = AppStrings.localized("mcp.tool.updateCard.description")
  static let updateCardIDParam = AppStrings.localized("mcp.tool.card.id")
  static let updateCardBodyParam = AppStrings.localized("mcp.tool.updateCard.body")
  static let updateCardCategoryParam = AppStrings.localized("mcp.tool.updateCard.category")
  static let deleteCardDescription = AppStrings.localized("mcp.tool.deleteCard.description")
  static let deleteCardCategoryParam = AppStrings.localized("mcp.tool.deleteCard.category")
  static let countCardsDescription = AppStrings.localized("mcp.tool.countCards.description")
  static let listCategoriesDescription = AppStrings.localized(
    "mcp.tool.listCategories.description")
  static let createCategoryDescription = AppStrings.localized(
    "mcp.tool.createCategory.description")
  static let createCategoryNameParam = AppStrings.localized("mcp.tool.category.name")
  static let renameCategoryDescription = AppStrings.localized(
    "mcp.tool.renameCategory.description")
  static let renameCategoryFromParam = AppStrings.localized("mcp.tool.renameCategory.from")
  static let renameCategoryToParam = AppStrings.localized("mcp.tool.renameCategory.to")
  static let deleteCategoryDescription = AppStrings.localized(
    "mcp.tool.deleteCategory.description")
  static let deleteCategoryNameParam = AppStrings.localized("mcp.tool.category.name")
  static let enqueueNoticeDescription = AppStrings.localized(
    "mcp.tool.enqueueNotice.description")
  static let enqueueNoticeMarkdownParam = AppStrings.localized(
    "mcp.tool.enqueueNotice.markdown")

  // MARK: - Success messages

  static let deleted = AppStrings.localized("mcp.result.deleted")
  static let created = AppStrings.localized("mcp.result.created")
  static let renamed = AppStrings.localized("mcp.result.renamed")

  // MARK: - Error messages

  static let missingBody = AppStrings.localized("mcp.error.missingBody")
  static let missingIDBodyCategory = AppStrings.localized("mcp.error.missingIDBodyCategory")
  static let missingIDCategory = AppStrings.localized("mcp.error.missingIDCategory")
  static let missingName = AppStrings.localized("mcp.error.missingName")
  static let missingFromTo = AppStrings.localized("mcp.error.missingFromTo")
  static let missingMarkdown = AppStrings.localized("mcp.error.missingMarkdown")

  static func cardNotFound(_ id: String) -> String {
    String(format: AppStrings.localized("mcp.error.cardNotFound"), id)
  }

  static func invalidCategoryName(_ name: String) -> String {
    String(format: AppStrings.localized("mcp.error.invalidCategoryName"), name)
  }

  static func categoryAlreadyExists(_ name: String) -> String {
    String(format: AppStrings.localized("mcp.error.categoryAlreadyExists"), name)
  }

  static func categoryNotFound(_ name: String) -> String {
    String(format: AppStrings.localized("mcp.error.categoryNotFound"), name)
  }

  static func categoryNotRenamable(_ name: String) -> String {
    String(format: AppStrings.localized("mcp.error.categoryNotRenamable"), name)
  }

  static func categoryNotDeletable(_ name: String) -> String {
    String(format: AppStrings.localized("mcp.error.categoryNotDeletable"), name)
  }

  static func invalidCardID(_ id: String) -> String {
    String(format: AppStrings.localized("mcp.error.invalidCardID"), id)
  }

  static func missingFrontMatter(_ filename: String) -> String {
    String(format: AppStrings.localized("mcp.error.missingFrontMatter"), filename)
  }

  static func unknownTool(_ name: String) -> String {
    String(format: AppStrings.localized("mcp.error.unknownTool"), name)
  }

  static func createCardCategoryDefault() -> String {
    String(
      format: AppStrings.localized("mcp.tool.createCard.categoryDefault"),
      AppMetadata.defaultCategoryDirectoryName)
  }
}
