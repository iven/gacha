import AppKit
import SwiftUI

/// Three-column card management layout shown in a SwiftUI `Window` scene.
/// Replaces the former `NSSplitViewController` tree and NSWindow shell.
struct CardManagementView: View {
  @ObservedObject var model: CardManagementModel
  @EnvironmentObject private var bridge: CardWindowBridge
  @State private var preferredCompactColumn: NavigationSplitViewColumn = .detail

  var body: some View {
    NavigationSplitView(preferredCompactColumn: $preferredCompactColumn) {
      CardCategorySidebar(model: model)
        .navigationSplitViewColumnWidth(min: 210, ideal: 230)
    } content: {
      CardListColumn(model: model)
        .navigationSplitViewColumnWidth(min: 220, ideal: 240)
        .navigationTitle(
          model.selectedCategory?.displayName ?? CardManagementStrings.uncategorized
        )
        .navigationSubtitle(subtitle)
    } detail: {
      editor
        .navigationSplitViewColumnWidth(min: 420, ideal: 560)
        .toolbar { toolbarContent }
    }
    // The column minimums imply a horizontal floor, but height is otherwise
    // unconstrained, so the window can be dragged down to a uselessly short
    // sliver. Pin a sensible minimum content size for both axes.
    .frame(minWidth: 860, minHeight: 480)
    .sheet(item: $model.activeSheet, content: sheet)
    .alert(item: $model.pendingDeletion, content: deletionAlert)
    .onAppear {
      // Route the model's preview pin into the shared bridge so the notch
      // presenter (observing the bridge) reflects it.
      model.onPreviewCardChange = { [weak bridge] card in
        bridge?.previewCard = card
      }
      bridge.setCardWindowVisible(true)
      consumePendingEdit()
    }
    .onDisappear {
      model.flushPendingEdits()
      model.exitPreview()
      bridge.setCardWindowVisible(false)
    }
    .onChange(of: bridge.pendingEditCardID) { _, _ in
      consumePendingEdit()
    }
  }

  private func consumePendingEdit() {
    guard let id = bridge.pendingEditCardID else {
      return
    }
    model.selectCard(byID: id)
    bridge.pendingEditCardID = nil
  }

  @ToolbarContentBuilder
  private var toolbarContent: some ToolbarContent {
    ToolbarItem {
      Button {
        model.createCard()
      } label: {
        Label(CardManagementStrings.newCard, systemImage: "square.and.pencil")
      }
    }
    // Push the new-card button to the leading edge, the rest to the trailing.
    if #available(macOS 26, *) {
      ToolbarSpacer(.flexible)
    } else {
      ToolbarItem { Spacer() }
    }
    ToolbarItem {
      Toggle(
        isOn: Binding(
          get: { model.isPreviewing },
          set: { _ in model.togglePreview() })
      ) {
        Label(
          CardManagementStrings.previewCard,
          systemImage: model.isPreviewing ? "eye.fill" : "eye")
      }
      .toggleStyle(.button)
      .disabled(!model.isPreviewing && model.selectedCard == nil)
    }
    // On macOS 26 a fixed spacer splits the shared Liquid Glass capsule so the
    // preview and delete buttons read as separate controls. Pre-26 has no
    // capsule, so the buttons are already distinct without it.
    if #available(macOS 26, *) {
      ToolbarSpacer(.fixed)
    }
    ToolbarItem {
      Button {
        if let card = model.selectedCard {
          model.pendingDeletion = .card(card)
        }
      } label: {
        Label(CardManagementStrings.deleteCard, systemImage: "trash")
      }
      .disabled(model.selectedCard == nil)
    }
  }

  @ViewBuilder
  private var editor: some View {
    if model.selectedCard != nil {
      MarkdownSourceEditor(
        text: Binding(
          get: { model.editorText },
          set: { model.updateBody($0) }))
    } else {
      // An empty editor area that creates a card on click, mirroring the former
      // AppKit editor's click-to-create empty state. NSCursor on hover (rather
      // than SwiftUI's pointerStyle) keeps the I-beam scoped to this region;
      // pointerStyle propagates into the column's toolbar.
      Color.clear
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onHover { hovering in
          if hovering {
            NSCursor.iBeam.push()
          } else {
            NSCursor.pop()
          }
        }
        .onTapGesture(perform: model.createCard)
    }
  }

  private var subtitle: String {
    String(
      format: CardManagementStrings.cardCountSubtitleFormat,
      model.selectedCategory?.cardCount ?? 0)
  }

  @ViewBuilder
  private func sheet(_ sheet: CardManagementModel.ActiveSheet) -> some View {
    switch sheet {
    case .newCategory:
      CategoryNameSheet(
        mode: .create,
        validate: { model.validateCategoryName($0) },
        onSubmit: { model.createCategory(name: $0) })
    case .renameCategory(let category):
      CategoryNameSheet(
        mode: .rename(category),
        validate: { model.validateCategoryName($0, excluding: category.directory) },
        onSubmit: { model.renameCategory(category, to: $0) })
    }
  }

  private func deletionAlert(_ pending: CardManagementModel.PendingDeletion) -> Alert {
    switch pending {
    case .card(let card):
      return Alert(
        title: Text(
          String.localizedStringWithFormat(
            CardManagementStrings.deleteCardConfirmationTitle,
            CardListItem(card: card).displayTitle)),
        message: Text(CardManagementStrings.deleteCardConfirmationMessage),
        primaryButton: .destructive(
          Text(CardManagementStrings.deleteCardConfirmationDelete),
          action: { model.delete(card: card) }),
        secondaryButton: .cancel(Text(CardManagementStrings.deleteCardConfirmationCancel)))
    case .category(let category):
      return Alert(
        title: Text(
          String.localizedStringWithFormat(
            CardManagementStrings.deleteCategoryConfirmationTitle,
            category.displayName)),
        message: Text(
          String.localizedStringWithFormat(
            CardManagementStrings.deleteCategoryConfirmationMessageFormat,
            category.cardCount)),
        primaryButton: .destructive(
          Text(CardManagementStrings.deleteCategoryConfirmationDelete),
          action: { model.deleteCategory(category) }),
        secondaryButton: .cancel(Text(CardManagementStrings.deleteCategoryConfirmationCancel)))
    }
  }
}
