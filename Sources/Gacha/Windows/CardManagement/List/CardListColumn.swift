import SwiftUI

/// Card list column for the selected category. Replaces
/// `CardListColumnViewController` + `CardListCellView` + `CardListEmptyStateView`.
struct CardListColumn: View {
  @ObservedObject var model: CardManagementModel

  var body: some View {
    let cards = model.categoryCards
    Group {
      if cards.isEmpty {
        emptyState
      } else {
        List(selection: selectionBinding) {
          ForEach(cards) { card in
            row(card)
              .tag(card.id)
              .contextMenu {
                contextMenu(for: card)
              }
          }
          .listRowSeparator(.hidden)
        }
      }
    }
    // An empty toolbar section gives this column its own segment in the window
    // title bar, so its navigationTitle gets a dedicated area instead of
    // overlapping the column divider (macOS only splits the title bar when both
    // the content and detail columns carry toolbar items).
    .toolbar {
      if #available(macOS 26, *) {
        ToolbarSpacer()
      } else {
        ToolbarItem { Spacer() }
      }
    }
  }

  private var selectionBinding: Binding<String?> {
    Binding(
      get: { model.selectedCardID },
      set: { model.selectCard(id: $0) })
  }

  private func row(_ card: MemoryCard) -> some View {
    let item = CardListItem(card: card)
    return VStack(alignment: .leading, spacing: 3) {
      Text(item.displayTitle)
        .fontWeight(.bold)
        .lineLimit(1)
      Text(item.subtitle)
        .font(.caption)
        .lineLimit(1)
    }
    .padding(.horizontal, 18)
    .padding(.vertical, 9)
  }

  @ViewBuilder
  private func contextMenu(for card: MemoryCard) -> some View {
    let targets = model.moveTargets(for: card)
    Menu {
      ForEach(targets, id: \.name) { target in
        Button(target.displayName) {
          model.moveCard(card, toCategory: target.name)
        }
      }
    } label: {
      Label(CardManagementStrings.moveCardMenuItem, systemImage: "folder")
    }
    .disabled(targets.isEmpty)

    Button(role: .destructive) {
      model.pendingDeletion = .card(card)
    } label: {
      Label(CardManagementStrings.deleteCardMenuItem, systemImage: "trash")
    }
  }

  private var emptyState: some View {
    Text(CardManagementStrings.emptyCategory)
      .font(.system(size: 30, weight: .semibold))
      .foregroundStyle(.tertiary)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
