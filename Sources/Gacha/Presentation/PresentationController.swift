import AppKit
import Combine
import DynamicNotchKit
import SwiftUI

@MainActor
final class PresentationController {
  var onNewCardRequested: (() -> Void)?
  var onEditCardRequested: ((MemoryCard) -> Void)?
  var onSettingsRequested: (() -> Void)?

  private let memoryCardRepository: MemoryCardRepository
  private let scheduler: MemoryCardScheduler
  private let settingsStore: SettingsStore
  private let now: () -> Date
  private let viewModel = PresentationViewModel()
  private var notch: DynamicNotch<AnyView, AnyView, AnyView>?
  private var hoverObservation: AnyCancellable?
  private var autoCollapseTask: Task<Void, Never>?
  private var globalClickMonitor: Any?
  private var isHovering = false

  init(
    memoryCardRepository: MemoryCardRepository,
    settingsStore: SettingsStore,
    scheduler: MemoryCardScheduler = MemoryCardScheduler(),
    now: @escaping () -> Date = Date.init
  ) {
    self.memoryCardRepository = memoryCardRepository
    self.settingsStore = settingsStore
    self.scheduler = scheduler
    self.now = now
  }

  func start() {
    refreshCurrentCard()

    let viewModel = self.viewModel
    let scheduler = self.scheduler
    let now = self.now
    let actions = MemoryCardActions(
      isDue: { card in scheduler.isDue(card, now: now()) },
      onRate: { [weak self] card, rating in self?.handleRating(card: card, rating: rating) },
      onNext: { [weak self] card in self?.handleNext(card: card) },
      onNewCard: { [weak self] in self?.onNewCardRequested?() },
      onEditCard: { [weak self] card in self?.onEditCardRequested?(card) },
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
    installGlobalClickMonitor()
  }

  private func installGlobalClickMonitor() {
    globalClickMonitor = NSEvent.addGlobalMonitorForEvents(
      matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.handleGlobalClick()
      }
    }
  }

  private func handleGlobalClick() {
    guard !isHovering, autoCollapseTask != nil else {
      return
    }

    cancelAutoCollapse()
    Task { await notch?.compact() }
  }

  private func handleHoverChange(_ hovering: Bool) {
    guard let notch else {
      return
    }

    isHovering = hovering
    if hovering {
      cancelAutoCollapse()
      Task {
        await notch.expand()
        notch.windowController?.window?.makeKeyAndOrderFront(nil)
      }
    } else {
      scheduleAutoCollapse()
    }
  }

  private func scheduleAutoCollapse() {
    cancelAutoCollapse()
    guard let timeout = currentAutoCollapseTimeout() else {
      return
    }

    autoCollapseTask = Task { [weak self] in
      if timeout > .zero {
        try? await Task.sleep(for: timeout)
      }
      guard let self, !Task.isCancelled else {
        return
      }

      await self.notch?.compact()
    }
  }

  private func cancelAutoCollapse() {
    autoCollapseTask?.cancel()
    autoCollapseTask = nil
  }

  private func currentAutoCollapseTimeout() -> Duration? {
    viewModel.currentCard.autoCollapseTimeout(
      memoryAutoCollapseSeconds: settingsStore.memoryAutoCollapseSeconds)
  }

  private func handleRating(card: MemoryCard, rating: MemoryCardRating) {
    do {
      let updated = try scheduler.apply(rating: rating, to: card, now: now())
      try memoryCardRepository.write(updated)
    } catch {
      AppLogger.app.warning("Failed to apply rating: \(error.localizedDescription)")
    }
    refreshCurrentCard()
  }

  private func handleNext(card: MemoryCard) {
    do {
      try memoryCardRepository.write(scheduler.markSeen(card, now: now()))
    } catch {
      AppLogger.app.warning("Failed to mark card as seen: \(error.localizedDescription)")
    }
    refreshCurrentCard()
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
    if !isHovering {
      scheduleAutoCollapse()
    }
  }
}

@MainActor
private final class PresentationViewModel: ObservableObject {
  @Published var currentCard: any Card = EmptyStateCard()
}

struct MemoryCardActions {
  let isDue: (MemoryCard) -> Bool
  let onRate: (MemoryCard, MemoryCardRating) -> Void
  let onNext: (MemoryCard) -> Void
  let onNewCard: () -> Void
  let onEditCard: (MemoryCard) -> Void
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
  // 48pt on each remaining edge (NotchView.swift). The card height fills the
  // available area; the width is the PRD-specified design width.
  private static let dynamicNotchKitEdgeInset: CGFloat = 48
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
        toolButton(symbol: "square.and.pencil") {
          actions.onEditCard(card)
        }
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
        if isDue {
          ratingButton(PresentationStrings.ratingAgain, tint: .ratingAgain, rating: .again)
          ratingButton(PresentationStrings.ratingHard, tint: .ratingHard, rating: .hard)
          ratingButton(PresentationStrings.ratingGood, tint: .ratingGood, rating: .good)
          ratingButton(PresentationStrings.ratingEasy, tint: .ratingEasy, rating: .easy)
        } else {
          ratingButton("", tint: .ratingAgain, rating: .again)
            .hidden()
            .allowsHitTesting(false)
          ratingButton("", tint: .ratingHard, rating: .hard)
            .hidden()
            .allowsHitTesting(false)
          ratingButton("", tint: .ratingGood, rating: .good)
            .hidden()
            .allowsHitTesting(false)
          nextButton
        }
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

  private var isDue: Bool {
    actions.isDue(card)
  }

  private var nextButton: some View {
    Button {
      actions.onNext(card)
    } label: {
      Text(PresentationStrings.ratingNext)
        .foregroundStyle(.white.opacity(0.8))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.ratingNext.opacity(0.25), in: RoundedRectangle(cornerRadius: 6))
    }
    .buttonStyle(.plain)
    .pointingCursor(.arrow)
  }

  private func ratingButton(_ label: String, tint: Color, rating: MemoryCardRating) -> some View {
    Button {
      actions.onRate(card, rating)
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
  fileprivate static let ratingNext = Color(white: 0.6)
}
