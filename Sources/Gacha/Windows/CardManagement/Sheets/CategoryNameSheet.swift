import SwiftUI

/// Create / rename category sheet. Reuses `validateNewCategoryName` through the
/// model's `validateCategoryName` so validation matches the former AppKit sheet.
struct CategoryNameSheet: View {
  enum Mode {
    case create
    case rename(CardCategoryItem)
  }

  let mode: Mode
  let validate: (String) -> String?
  let onSubmit: (String) -> Void

  @Environment(\.dismiss) private var dismiss
  @State private var name: String
  @State private var errorMessage: String?
  @FocusState private var nameFieldFocused: Bool

  init(
    mode: Mode,
    validate: @escaping (String) -> String?,
    onSubmit: @escaping (String) -> Void
  ) {
    self.mode = mode
    self.validate = validate
    self.onSubmit = onSubmit
    switch mode {
    case .create:
      _name = State(initialValue: CardManagementStrings.newCategoryDefaultName)
    case .rename(let category):
      _name = State(initialValue: category.directory)
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.headline)
      Text(message)
        .font(.caption)
        .foregroundStyle(.secondary)

      TextField("", text: $name)
        .textFieldStyle(.roundedBorder)
        .focused($nameFieldFocused)
        .onSubmit(submit)
        .padding(.top, 6)

      Divider()
        .padding(.vertical, 6)

      HStack {
        if let errorMessage {
          Text(errorMessage)
            .font(.caption)
            .foregroundStyle(.red)
        }
        Spacer()
        Button(CardManagementStrings.newCategoryCancel, role: .cancel) {
          dismiss()
        }
        .keyboardShortcut(.cancelAction)
        Button(submitTitle, action: submit)
          .keyboardShortcut(.defaultAction)
      }
    }
    .padding(20)
    .frame(width: 360)
    .onAppear { nameFieldFocused = true }
  }

  private var title: String {
    switch mode {
    case .create:
      return CardManagementStrings.newCategorySheetTitle
    case .rename:
      return CardManagementStrings.renameCategorySheetTitle
    }
  }

  private var message: String {
    switch mode {
    case .create:
      return CardManagementStrings.newCategorySheetMessage
    case .rename:
      return CardManagementStrings.renameCategorySheetMessage
    }
  }

  private var submitTitle: String {
    switch mode {
    case .create:
      return CardManagementStrings.newCategoryCreate
    case .rename:
      return CardManagementStrings.renameCategoryConfirm
    }
  }

  private func submit() {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    if let error = validate(trimmed) {
      errorMessage = error
      nameFieldFocused = true
      return
    }

    dismiss()
    onSubmit(trimmed)
  }
}
