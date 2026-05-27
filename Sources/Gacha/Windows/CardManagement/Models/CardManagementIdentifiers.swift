import AppKit

extension NSUserInterfaceItemIdentifier {
  static let categoryName = NSUserInterfaceItemIdentifier("Gacha.CardManagement.CategoryName")
  static let categoryCell = NSUserInterfaceItemIdentifier("Gacha.CardManagement.CategoryCell")
  static let cardTitle = NSUserInterfaceItemIdentifier("Gacha.CardManagement.CardTitle")
  static let cardCell = NSUserInterfaceItemIdentifier("Gacha.CardManagement.CardCell")
  static let moveCardMenuItem = NSUserInterfaceItemIdentifier(
    "Gacha.CardManagement.MoveCardMenuItem")
}

extension NSToolbar.Identifier {
  static let cardManagement = NSToolbar.Identifier("Gacha.CardManagement")
}

extension NSToolbarItem.Identifier {
  static let newCategory = NSToolbarItem.Identifier("Gacha.CardManagement.NewCategory")
  static let newCard = NSToolbarItem.Identifier("Gacha.CardManagement.NewCard")
  static let deleteCard = NSToolbarItem.Identifier("Gacha.CardManagement.DeleteCard")
  static let previewCard = NSToolbarItem.Identifier("Gacha.CardManagement.PreviewCard")
}
