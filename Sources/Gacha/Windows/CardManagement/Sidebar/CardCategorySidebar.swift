import SwiftUI

/// Categories sidebar. Replaces `CardCategorySidebarViewController` +
/// `CardCategoryCellView`.
struct CardCategorySidebar: View {
  @ObservedObject var model: CardManagementModel

  var body: some View {
    List(selection: selectionBinding) {
      Section(CardManagementStrings.sidebarTitle) {
        ForEach(model.categories, id: \.directory) { category in
          row(category)
            .tag(category.directory)
            .contextMenu {
              if model.isUserCategory(category) {
                Button {
                  model.activeSheet = .renameCategory(category)
                } label: {
                  Label(CardManagementStrings.renameCategoryMenuItem, systemImage: "pencil")
                }
                Button(role: .destructive) {
                  model.pendingDeletion = .category(category)
                } label: {
                  Label(CardManagementStrings.deleteCategoryMenuItem, systemImage: "trash")
                }
              }
            }
        }
      }
    }
    // Hosted in the sidebar column's toolbar so it sits at the sidebar leading
    // edge, mirroring the system sidebar toggle on the trailing edge (same
    // layout as Notes' "New Folder" button). A bare Button (default .automatic
    // placement) lands in the sidebar region; wrapping it in
    // ToolbarItem(placement: .navigation) instead forces it next to the toggle.
    .toolbar {
      Button {
        model.activeSheet = .newCategory
      } label: {
        Label(CardManagementStrings.newCategory, systemImage: "folder.badge.plus")
      }
    }
  }

  private var selectionBinding: Binding<String?> {
    Binding(
      get: { model.selectedDirectory },
      set: { newValue in
        if let newValue {
          model.selectCategory(newValue)
        }
      })
  }

  private func row(_ category: CardCategoryItem) -> some View {
    HStack(spacing: 7) {
      Image(systemName: "folder")
        .foregroundStyle(.secondary)
      Text(category.displayName)
        .lineLimit(1)
      Spacer(minLength: 8)
      Text("\(category.cardCount)")
        .foregroundStyle(.secondary)
        .monospacedDigit()
    }
  }
}
