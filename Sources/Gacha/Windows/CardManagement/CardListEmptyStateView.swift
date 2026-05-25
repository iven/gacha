import AppKit

final class CardListEmptyStateView: NSView {
  var title: String {
    get { titleField.stringValue }
    set { titleField.stringValue = newValue }
  }

  private let titleField = NSTextField(labelWithString: "")

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    titleField.font = .systemFont(ofSize: 30, weight: .semibold)
    titleField.textColor = .tertiaryLabelColor

    titleField.translatesAutoresizingMaskIntoConstraints = false
    addSubview(titleField)

    NSLayoutConstraint.activate([
      titleField.centerXAnchor.constraint(equalTo: centerXAnchor),
      titleField.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -24),
      titleField.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
      titleField.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
