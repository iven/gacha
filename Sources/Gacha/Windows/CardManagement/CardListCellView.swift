import AppKit

final class CardListCellView: NSTableCellView {
  private let titleField = NSTextField(labelWithString: "")
  private let subtitleField = NSTextField(labelWithString: "")

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    identifier = .cardCell

    titleField.font = .preferredFont(forTextStyle: .body)
    titleField.lineBreakMode = .byTruncatingTail
    subtitleField.font = .preferredFont(forTextStyle: .caption1)
    subtitleField.textColor = .secondaryLabelColor
    subtitleField.lineBreakMode = .byTruncatingTail

    [titleField, subtitleField].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      addSubview($0)
    }

    NSLayoutConstraint.activate([
      titleField.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      titleField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      titleField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

      subtitleField.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 3),
      subtitleField.leadingAnchor.constraint(equalTo: titleField.leadingAnchor),
      subtitleField.trailingAnchor.constraint(equalTo: titleField.trailingAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ item: CardListItem) {
    titleField.stringValue = item.displayTitle
    subtitleField.stringValue = item.subtitle
  }
}
