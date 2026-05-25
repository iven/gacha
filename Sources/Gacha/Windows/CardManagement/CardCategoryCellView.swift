import AppKit

final class CardCategoryCellView: NSTableCellView {
  private let iconView = NSImageView()
  private let titleField = NSTextField(labelWithString: "")
  private let countField = NSTextField(labelWithString: "")

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    identifier = .categoryCell

    titleField.lineBreakMode = .byTruncatingTail
    countField.textColor = .secondaryLabelColor
    countField.alignment = .right

    [iconView, titleField, countField].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      addSubview($0)
    }

    NSLayoutConstraint.activate([
      iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
      iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
      iconView.widthAnchor.constraint(equalToConstant: 16),
      iconView.heightAnchor.constraint(equalToConstant: 16),

      titleField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 7),
      titleField.centerYAnchor.constraint(equalTo: centerYAnchor),

      countField.leadingAnchor.constraint(
        greaterThanOrEqualTo: titleField.trailingAnchor, constant: 8),
      countField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
      countField.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ category: CardCategoryItem) {
    iconView.image = NSImage(
      systemSymbolName: "folder",
      accessibilityDescription: category.displayName)
    titleField.stringValue = category.displayName
    countField.stringValue = "\(category.cardCount)"
  }
}
