import AppKit
import Combine
import DynamicNotchKit
import SwiftUI

@MainActor
final class NotchController {
  var onNewCardRequested: (() -> Void)?
  var onEditCardRequested: ((MemoryCard) -> Void)?
  var onSettingsRequested: (() -> Void)?
  var onPausedChange: ((Bool) -> Void)?

  private let memoryCardRepository: MemoryCardRepository
  private let scheduler: MemoryCardScheduler
  private let settingsStore: SettingsStore
  private let now: () -> Date
  private let viewModel = NotchViewModel()
  private var notch: DynamicNotch<AnyView, AnyView, AnyView>?
  private var hoverObservation: AnyCancellable?
  private var repositoryEventObservation: AnyCancellable?
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
    viewModel.onResumeRequested = { [weak self] in
      self?.setPaused(false)
    }

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
        AnyView(NotchExpandedView(viewModel: viewModel, actions: actions))
      },
      compactLeading: { AnyView(LogoCompactView()) },
      compactTrailing: { AnyView(CompactTrailingView(viewModel: viewModel)) })
    self.notch = notch
    Task { await notch.compact() }
    hoverObservation =
      notch.$isHovering
      .removeDuplicates()
      .sink { [weak self] hovering in
        self?.handleHoverChange(hovering)
      }
    repositoryEventObservation =
      memoryCardRepository.events
      .receive(on: DispatchQueue.main)
      .sink { [weak self] event in
        self?.handleRepositoryEvent(event)
      }
    installGlobalClickMonitor()
  }

  func setPaused(_ paused: Bool) {
    guard viewModel.isPaused != paused else {
      return
    }

    viewModel.isPaused = paused
    if paused {
      cancelAutoCollapse()
      Task { await notch?.compact() }
    } else if isHovering, let notch {
      cancelAutoCollapse()
      Task {
        await notch.expand()
        notch.windowController?.window?.makeKeyAndOrderFront(nil)
      }
    }
    onPausedChange?(paused)
  }

  private func handleRepositoryEvent(_ event: MemoryCardRepositoryEvent) {
    switch event {
    case .didUpdate(let card):
      if let current = viewModel.currentCard as? MemoryCard, current.id == card.id {
        viewModel.currentCard = card
      }
    case .didDelete(let id, _):
      if let current = viewModel.currentCard as? MemoryCard, current.id == id {
        refreshCurrentCard()
      }
    case .didCreate:
      if viewModel.currentCard is EmptyStateCard {
        refreshCurrentCard()
      }
    case .didDeleteDirectory(let name):
      if let current = viewModel.currentCard as? MemoryCard, current.directory == name {
        refreshCurrentCard()
      }
    case .didMoveDirectory(let oldName, _):
      if let current = viewModel.currentCard as? MemoryCard, current.directory == oldName {
        refreshCurrentCard()
      }
    case .didRebuildIndex:
      refreshCurrentCard()
    }
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
    if viewModel.isPaused {
      cancelAutoCollapse()
      return
    }

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
