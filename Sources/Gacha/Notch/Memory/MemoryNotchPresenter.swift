import Combine
import Foundation
import SwiftUI

@MainActor
final class MemoryNotchPresenter: ObservableObject {
  enum Mode: Equatable {
    case scheduler
    case preview(MemoryCard)
  }

  var onNewCardRequested: (() -> Void)?
  var onEditCardRequested: ((MemoryCard) -> Void)?

  @Published private(set) var currentCard: any Card = EmptyStateCard()
  @Published private(set) var mode: Mode = .scheduler

  var actions: MemoryCardActions {
    MemoryCardActions(
      isDue: { [scheduler, now] card in scheduler.isDue(card, now: now()) },
      onRate: { [weak self] card, rating in self?.handleRating(card: card, rating: rating) },
      onNext: { [weak self] card in self?.handleNext(card: card) },
      onNewCard: { [weak self] in self?.onNewCardRequested?() },
      onEditCard: { [weak self] card in self?.onEditCardRequested?(card) },
      onDismiss: { [weak self] in self?.controller.compact() })
  }

  var isInteractive: Bool {
    if case .preview = mode { return false }
    return true
  }

  var showKeyboardHints: Bool {
    settingsStore.showKeyboardHints
  }

  private let controller: NotchController
  private let memoryCardRepository: MemoryCardRepository
  private let scheduler: MemoryCardScheduler
  private let settingsStore: SettingsStore
  private let now: () -> Date
  private var repositoryEventObservation: AnyCancellable?
  private var hasVisibleManagedWindow = false

  init(
    controller: NotchController,
    memoryCardRepository: MemoryCardRepository,
    settingsStore: SettingsStore,
    scheduler: MemoryCardScheduler = MemoryCardScheduler(),
    now: @escaping () -> Date = Date.init
  ) {
    self.controller = controller
    self.memoryCardRepository = memoryCardRepository
    self.settingsStore = settingsStore
    self.scheduler = scheduler
    self.now = now
  }

  func start() {
    refreshScheduledCard()
    repositoryEventObservation =
      memoryCardRepository.events
      .receive(on: DispatchQueue.main)
      .sink { [weak self] event in
        self?.handleRepositoryEvent(event)
      }
  }

  func setPreviewCard(_ card: MemoryCard?) {
    if let card {
      mode = .preview(card)
      show(card: card)
    } else if case .preview = mode {
      mode = .scheduler
      refreshScheduledCard()
    }
  }

  func setHasVisibleManagedWindow(_ visible: Bool) {
    guard hasVisibleManagedWindow != visible else {
      return
    }
    hasVisibleManagedWindow = visible
    show(card: currentCard)
  }

  private func handleRepositoryEvent(_ event: MemoryCardRepositoryEvent) {
    switch event {
    case .didUpdate(let card):
      if case .preview(let current) = mode, current.id == card.id {
        mode = .preview(card)
        show(card: card)
      } else if let current = currentCard as? MemoryCard, current.id == card.id {
        currentCard = card
      }
    case .didDelete(let id, _):
      if case .preview(let current) = mode, current.id == id {
        setPreviewCard(nil)
      } else if let current = currentCard as? MemoryCard, current.id == id {
        refreshScheduledCard()
      }
    case .didCreate:
      if case .scheduler = mode, currentCard is EmptyStateCard {
        refreshScheduledCard()
      }
    case .didDeleteDirectory(let name):
      if case .preview(let current) = mode, current.directory == name {
        setPreviewCard(nil)
      } else if let current = currentCard as? MemoryCard, current.directory == name {
        refreshScheduledCard()
      }
    case .didMoveDirectory(let oldName, _):
      if case .preview(let current) = mode, current.directory == oldName {
        setPreviewCard(nil)
      } else if let current = currentCard as? MemoryCard, current.directory == oldName {
        refreshScheduledCard()
      }
    case .didRebuildIndex:
      if case .scheduler = mode {
        refreshScheduledCard()
      }
    }
  }

  private func handleRating(card: MemoryCard, rating: MemoryCardRating) {
    guard isInteractive else { return }
    do {
      let updated = try scheduler.apply(rating: rating, to: card, now: now())
      try memoryCardRepository.write(updated)
    } catch {
      AppLogger.app.warning("Failed to apply rating: \(error.localizedDescription)")
    }
    refreshScheduledCard()
  }

  private func handleNext(card: MemoryCard) {
    guard isInteractive else { return }
    do {
      try memoryCardRepository.write(scheduler.markSeen(card, now: now()))
    } catch {
      AppLogger.app.warning("Failed to mark card as seen: \(error.localizedDescription)")
    }
    refreshScheduledCard()
  }

  private func refreshScheduledCard() {
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
    show(card: nextCard)
  }

  private func show(card: any Card) {
    currentCard = card
    let timeout: Duration?
    if case .preview = mode {
      timeout = nil
    } else if hasVisibleManagedWindow, settingsStore.skipCountdownOnAnotherWindow {
      timeout = .zero
    } else {
      timeout = card.autoCollapseTimeout(
        memoryAutoCollapseSeconds: settingsStore.memoryAutoCollapseSeconds)
    }
    controller.setAutoCollapseTimeout(timeout)
    if case .preview = mode {
      controller.expand()
    }
  }
}
