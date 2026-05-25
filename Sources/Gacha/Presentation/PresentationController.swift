import AppKit
import Combine
import DynamicNotchKit
import SwiftUI

@MainActor
final class PresentationController {
  var onNewCardRequested: (() -> Void)?
  var onEditCardRequested: (() -> Void)?
  var onSettingsRequested: (() -> Void)?

  private let memoryCardRepository: MemoryCardRepository
  private let scheduler: MemoryCardScheduler
  private let now: () -> Date
  private let viewModel = PresentationViewModel()
  private var notch: DynamicNotch<AnyView, AnyView, AnyView>?
  private var hoverObservation: AnyCancellable?

  init(
    memoryCardRepository: MemoryCardRepository,
    scheduler: MemoryCardScheduler = MemoryCardScheduler(),
    now: @escaping () -> Date = Date.init
  ) {
    self.memoryCardRepository = memoryCardRepository
    self.scheduler = scheduler
    self.now = now
  }

  func start() {
    refreshCurrentCard()

    let viewModel = self.viewModel
    let actions = MemoryCardActions(
      onNewCard: { [weak self] in self?.onNewCardRequested?() },
      onEditCard: { [weak self] in self?.onEditCardRequested?() },
      onSettings: { [weak self] in self?.onSettingsRequested?() })
    let notch = DynamicNotch(
      hoverBehavior: .all,
      style: .notch,
      expanded: {
        AnyView(PresentationExpandedView(viewModel: viewModel, actions: actions))
      },
      compactLeading: { AnyView(LogoCompactView()) },
      compactTrailing: { AnyView(LogoCompactView().hidden()) })
    self.notch = notch
    Task { await notch.compact() }
    hoverObservation =
      notch.$isHovering
      .removeDuplicates()
      .sink { [weak self] hovering in
        self?.handleHoverChange(hovering)
      }
  }

  private func handleHoverChange(_ hovering: Bool) {
    guard let notch else {
      return
    }

    Task {
      if hovering {
        await notch.expand()
        notch.windowController?.window?.makeKeyAndOrderFront(nil)
      } else {
        await notch.compact()
      }
    }
  }

  private func refreshCurrentCard() {
    let nextCard: any Card
    do {
      let cards = try memoryCardRepository.list()
      if let card = scheduler.pickNext(from: cards, now: now()) {
        nextCard = card
      } else {
        nextCard = EmptyStateCard()
      }
    } catch {
      AppLogger.app.warning(
        "Failed to load memory card for presentation: \(error.localizedDescription)")
      nextCard = EmptyStateCard()
    }
    viewModel.currentCard = nextCard
  }
}

@MainActor
private final class PresentationViewModel: ObservableObject {
  @Published var currentCard: any Card = EmptyStateCard()
}

struct MemoryCardActions {
  let onNewCard: () -> Void
  let onEditCard: () -> Void
  let onSettings: () -> Void
}

private struct PresentationExpandedView: View {
  @ObservedObject var viewModel: PresentationViewModel
  let actions: MemoryCardActions

  var body: some View {
    switch viewModel.currentCard {
    case let memoryCard as MemoryCard:
      MemoryCardExpandedView(card: memoryCard, actions: actions)
    default:
      EmptyStateExpandedView(action: actions.onNewCard)
    }
  }
}

private struct LogoCompactView: View {
  var body: some View {
    Text("G")
      .font(.system(size: 11, weight: .bold))
      .foregroundStyle(.white)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(.red, in: Capsule())
  }
}

private struct EmptyStateExpandedView: View {
  let action: () -> Void

  var body: some View {
    VStack(spacing: 12) {
      Text(PresentationStrings.emptyStateTitle)
        .font(.title.bold())
        .multilineTextAlignment(.center)
      Text(PresentationStrings.emptyStateBody)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      Button(action: action) {
        Text(PresentationStrings.emptyStateAction)
          .frame(maxWidth: .infinity, minHeight: 32)
      }
      .buttonStyle(.borderedProminent)
      .frame(width: 160)
      .padding(.top, 24)
    }
    .padding(48)
    .frame(width: 480)
  }
}

private struct MemoryCardExpandedView: View {
  let card: MemoryCard
  let actions: MemoryCardActions

  // DynamicNotchKit panel = screen.width/2 × screen.height/2, with the expanded
  // content sitting inside safeAreaInsets reserving the notch height on top and
  // 15pt on each remaining edge (NotchView.swift). The card height fills the
  // available area; the width is the PRD-specified design width.
  private static let dynamicNotchKitEdgeInset: CGFloat = 15
  private static let cardWidth: CGFloat = 480

  private var cardMaxHeight: CGFloat {
    let screen = NSScreen.main
    let panelHeight = (screen?.frame.height ?? 800) / 2
    let topInset = screen?.safeAreaInsets.top ?? 32
    return panelHeight - topInset - Self.dynamicNotchKitEdgeInset
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        LogoCompactView()
        Spacer()
        toolButton(symbol: "square.and.pencil", action: actions.onEditCard)
        toolButton(symbol: "gearshape", action: actions.onSettings)
      }
      .padding(.bottom, 4)
      ScrollView(.vertical) {
        bodyView
      }
      .padding(.vertical, 12)
      Divider()
        .padding(.vertical, 4)
      HStack(spacing: 8) {
        ratingButton(PresentationStrings.ratingAgain, tint: .ratingAgain)
        ratingButton(PresentationStrings.ratingHard, tint: .ratingHard)
        ratingButton(PresentationStrings.ratingGood, tint: .ratingGood)
        ratingButton(PresentationStrings.ratingEasy, tint: .ratingEasy)
      }
    }
    .padding(.horizontal, 8)
    .padding(.bottom, 8)
    .frame(width: Self.cardWidth, alignment: .leading)
    .frame(maxHeight: cardMaxHeight, alignment: .top)
  }

  @ViewBuilder
  private var bodyView: some View {
    let trimmed = card.body.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      Text(PresentationStrings.emptyBodyPlaceholder)
        .font(.title3)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    } else {
      Text(trimmed)
        .font(.title3)
        .foregroundStyle(.primary)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private func ratingButton(_ label: String, tint: Color) -> some View {
    Button {
    } label: {
      Text(label)
        .foregroundStyle(.white.opacity(0.8))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(tint.opacity(0.25), in: RoundedRectangle(cornerRadius: 6))
    }
    .buttonStyle(.plain)
    .pointingCursor(.arrow)
  }

  private func toolButton(symbol: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: symbol)
        .resizable()
        .scaledToFit()
        .frame(width: 14, height: 14)
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.white.opacity(0.12), in: Capsule())
    }
    .buttonStyle(.plain)
    .pointingCursor(.arrow)
  }
}

extension View {
  fileprivate func pointingCursor(_ cursor: NSCursor) -> some View {
    onHover { hovering in
      if hovering {
        cursor.push()
      } else {
        NSCursor.pop()
      }
    }
  }
}

extension Color {
  fileprivate static let ratingAgain = Color(red: 0.78, green: 0.36, blue: 0.36)
  fileprivate static let ratingHard = Color(red: 0.82, green: 0.60, blue: 0.36)
  fileprivate static let ratingGood = Color(red: 0.45, green: 0.72, blue: 0.62)
  fileprivate static let ratingEasy = Color(red: 0.45, green: 0.62, blue: 0.85)
}
