import AppKit

@MainActor
final class CardCategoryNameSheetController: NSViewController {
  typealias Validator = (String) -> ValidationResult

  enum ValidationResult {
    case valid
    case invalid(String)
  }

  static func makeNewCategorySheet(
    validate: @escaping Validator,
    onCreate: @escaping (String) -> Void
  ) -> CardCategoryNameSheetController {
    CardCategoryNameSheetController(
      title: CardManagementStrings.newCategorySheetTitle,
      message: CardManagementStrings.newCategorySheetMessage,
      initialName: CardManagementStrings.newCategoryDefaultName,
      submitTitle: CardManagementStrings.newCategoryCreate,
      cancelTitle: CardManagementStrings.newCategoryCancel,
      validate: validate,
      onSubmit: onCreate)
  }

  static func makeRenameCategorySheet(
    currentName: String,
    validate: @escaping Validator,
    onRename: @escaping (String) -> Void
  ) -> CardCategoryNameSheetController {
    CardCategoryNameSheetController(
      title: CardManagementStrings.renameCategorySheetTitle,
      message: CardManagementStrings.renameCategorySheetMessage,
      initialName: currentName,
      submitTitle: CardManagementStrings.renameCategoryConfirm,
      cancelTitle: CardManagementStrings.newCategoryCancel,
      validate: validate,
      onSubmit: onRename)
  }

  private let titleText: String
  private let messageText: String
  private let initialName: String
  private let submitTitle: String
  private let cancelTitle: String
  private let validate: Validator
  private let onSubmit: (String) -> Void

  private let nameField = NSTextField()
  private let errorField = NSTextField(labelWithString: "")
  private let buttonSeparator = NSBox()
  private var submitButton: NSButton?

  init(
    title: String,
    message: String,
    initialName: String,
    submitTitle: String,
    cancelTitle: String,
    validate: @escaping Validator,
    onSubmit: @escaping (String) -> Void
  ) {
    titleText = title
    messageText = message
    self.initialName = initialName
    self.submitTitle = submitTitle
    self.cancelTitle = cancelTitle
    self.validate = validate
    self.onSubmit = onSubmit
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func loadView() {
    let rootView = NSView()
    let titleField = NSTextField(labelWithString: titleText)
    let messageField = NSTextField(labelWithString: messageText)
    let cancelButton = NSButton(
      title: cancelTitle, target: self, action: #selector(cancel))
    let submitButton = NSButton(
      title: submitTitle, target: self, action: #selector(submit))

    titleField.font = .systemFont(ofSize: 13, weight: .semibold)
    messageField.font = .systemFont(ofSize: 11)
    messageField.textColor = .secondaryLabelColor
    nameField.stringValue = initialName
    nameField.font = .preferredFont(forTextStyle: .body)
    nameField.target = self
    nameField.action = #selector(submit)
    errorField.font = .systemFont(ofSize: 11)
    errorField.textColor = .systemRed
    errorField.isHidden = true
    cancelButton.bezelStyle = .rounded
    cancelButton.keyEquivalent = "\u{1b}"
    submitButton.bezelStyle = .rounded
    submitButton.keyEquivalent = "\r"
    self.submitButton = submitButton
    buttonSeparator.boxType = .separator

    [
      titleField, messageField, nameField, errorField, buttonSeparator, cancelButton,
      submitButton,
    ].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      rootView.addSubview($0)
    }

    NSLayoutConstraint.activate([
      titleField.topAnchor.constraint(equalTo: rootView.topAnchor, constant: 20),
      titleField.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: 20),
      titleField.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -20),

      messageField.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 8),
      messageField.leadingAnchor.constraint(equalTo: titleField.leadingAnchor),
      messageField.trailingAnchor.constraint(equalTo: titleField.trailingAnchor),

      nameField.topAnchor.constraint(equalTo: messageField.bottomAnchor, constant: 14),
      nameField.leadingAnchor.constraint(equalTo: titleField.leadingAnchor),
      nameField.trailingAnchor.constraint(equalTo: titleField.trailingAnchor),

      buttonSeparator.topAnchor.constraint(equalTo: nameField.bottomAnchor, constant: 14),
      buttonSeparator.leadingAnchor.constraint(equalTo: titleField.leadingAnchor),
      buttonSeparator.trailingAnchor.constraint(equalTo: titleField.trailingAnchor),
      buttonSeparator.heightAnchor.constraint(equalToConstant: 1),

      errorField.topAnchor.constraint(equalTo: buttonSeparator.bottomAnchor, constant: 12),
      errorField.leadingAnchor.constraint(equalTo: titleField.leadingAnchor),
      errorField.trailingAnchor.constraint(
        lessThanOrEqualTo: submitButton.leadingAnchor, constant: -12),
      errorField.centerYAnchor.constraint(equalTo: submitButton.centerYAnchor),

      submitButton.topAnchor.constraint(equalTo: buttonSeparator.bottomAnchor, constant: 12),
      submitButton.trailingAnchor.constraint(equalTo: titleField.trailingAnchor),
      submitButton.bottomAnchor.constraint(equalTo: rootView.bottomAnchor, constant: -20),
      submitButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 88),

      cancelButton.trailingAnchor.constraint(
        equalTo: submitButton.leadingAnchor, constant: -10),
      cancelButton.centerYAnchor.constraint(equalTo: submitButton.centerYAnchor),
      cancelButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 88),
    ])

    rootView.frame = NSRect(x: 0, y: 0, width: 360, height: 180)
    view = rootView
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    if let editor = view.window?.fieldEditor(true, for: nameField) as? NSTextView {
      view.window?.makeFirstResponder(nameField)
      editor.selectAll(nil)
    }
  }

  @objc private func submit() {
    let name = nameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    switch validate(name) {
    case .valid:
      hideError()
      let presenter = presentingViewController
      presenter?.dismiss(self)
      onSubmit(name)
    case .invalid(let message):
      showError(message)
      view.window?.makeFirstResponder(nameField)
    }
  }

  @objc private func cancel() {
    presentingViewController?.dismiss(self)
  }

  private func showError(_ message: String) {
    errorField.stringValue = message
    errorField.isHidden = false
  }

  private func hideError() {
    errorField.isHidden = true
    errorField.stringValue = ""
  }
}
