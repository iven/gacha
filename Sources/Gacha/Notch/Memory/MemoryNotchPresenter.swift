import Combine
import Foundation
import SwiftUI

@MainActor
final class MemoryNotchPresenter: ObservableObject {
  enum Mode: Equatable {
    /// Default. Scheduler picks the next card; rating advances; auto-collapse
    /// on hover-leave per settings.
    case scheduler
    /// User pinned the notch from the toolbar/`p` shortcut while no card
    /// management window is open. The notch stays expanded (no auto-collapse),
    /// but the card is still picked by the scheduler and rating still works.
    case pinned
    /// Card window pinned a specific card. The notch stays expanded, the card
    /// is locked, and rating buttons are disabled.
    case preview(MemoryCard)
  }

  var onPauseRequested: (() -> Void)?
  var onSettingsRequested: (() -> Void)?

  @Published private(set) var currentCard: any Card = EmptyStateCard()
  @Published private(set) var mode: Mode = .scheduler
  @Published private(set) var isCardWindowVisible: Bool = false
  @Published private(set) var isSettingsVisible: Bool = false

  var actions: MemoryCardActions {
    MemoryCardActions(
      isDue: { [scheduler, now] card in scheduler.isDue(card, now: now()) },
      onRate: { [weak self] card, rating in self?.handleRating(card: card, rating: rating) },
      onNext: { [weak self] card in self?.handleNext(card: card) },
      onNewCard: { [weak self] in self?.cardWindowBridge.requestOpen() },
      onEditCard: { [weak self] card in
        self?.cardWindowBridge.requestOpen(editingCardID: card.id)
      },
      onOpenSettings: { [weak self] in self?.onSettingsRequested?() },
      onPause: { [weak self] in self?.onPauseRequested?() },
      onDismiss: { [weak self] in self?.handleDismiss() },
      onTogglePin: { [weak self] in self?.handleTogglePin() })
  }

  var isInteractive: Bool {
    if case .preview = mode { return false }
    return true
  }

  /// True whenever the notch is held expanded by either pin or preview. View
  /// layer reads this to decide whether the toolbar pin/eye button is
  /// rendered as filled (active) or outlined.
  var isPinned: Bool {
    mode != .scheduler
  }

  /// Global-shortcut entry point for Ctrl+Option+G. Releases whatever is
  /// holding the notch open (preview or pin); otherwise toggles expand/collapse.
  func handleToggleShortcut() {
    switch mode {
    case .preview: cardWindowBridge.previewCard = nil
    case .pinned: mode = .scheduler
    case .scheduler: controller.toggle()
    }
  }

  /// Toolbar pin/eye button + `p` shortcut entry point. When the card window
  /// is open, defers to the model's preview toggle (so the model stays the
  /// single owner of preview state). Otherwise toggles the local pin state.
  func handleTogglePin() {
    if isCardWindowVisible {
      cardWindowBridge.togglePreviewRequest.send()
    } else if mode == .pinned {
      mode = .scheduler
    } else if case .scheduler = mode {
      mode = .pinned
    }
    // .preview while card window not visible should not be reachable: closing
    // the window clears bridge.previewCard which collapses .preview to .scheduler.
    show(card: currentCard)
  }

  private func handleDismiss() {
    switch mode {
    case .preview: cardWindowBridge.previewCard = nil
    case .pinned:
      mode = .scheduler
      show(card: currentCard)
    case .scheduler: controller.compact()
    }
  }

  var showKeyboardHints: Bool {
    settingsStore.showKeyboardHints
  }

  private let controller: NotchController
  private let memoryCardRepository: MemoryCardRepository
  private let scheduler: MemoryCardScheduler
  private let settingsStore: SettingsStore
  private let cardWindowBridge: CardWindowBridge
  private let now: () -> Date
  private var repositoryEventObservation: AnyCancellable?
  private var bridgeObservations: Set<AnyCancellable> = []
  private var hasVisibleManagedWindow = false

  init(
    controller: NotchController,
    memoryCardRepository: MemoryCardRepository,
    settingsStore: SettingsStore,
    cardWindowBridge: CardWindowBridge,
    scheduler: MemoryCardScheduler = MemoryCardScheduler(),
    now: @escaping () -> Date = Date.init
  ) {
    self.controller = controller
    self.memoryCardRepository = memoryCardRepository
    self.settingsStore = settingsStore
    self.cardWindowBridge = cardWindowBridge
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
    observeCardWindowBridge()
  }

  // Called by the settings UI when the idle-reminder interval changes, so a new
  // cadence takes effect immediately instead of waiting for the next card.
  func refreshIdleReminderTimeout() {
    controller.setIdleReminderTimeout(.seconds(settingsStore.idleReminderAnimationSeconds))
  }

  // Observes the shared bridge: the card window writes preview card and managed
  // window visibility, and the presenter reacts here.
  private func observeCardWindowBridge() {
    cardWindowBridge.$previewCard
      .removeDuplicates()
      .sink { [weak self] card in
        self?.setPreviewCard(card)
      }
      .store(in: &bridgeObservations)

    cardWindowBridge.$hasVisibleManagedWindow
      .removeDuplicates()
      .sink { [weak self] visible in
        self?.setHasVisibleManagedWindow(visible)
      }
      .store(in: &bridgeObservations)

    cardWindowBridge.$cardWindowVisible
      .removeDuplicates()
      .assign(to: &$isCardWindowVisible)
    cardWindowBridge.$settingsVisible
      .removeDuplicates()
      .assign(to: &$isSettingsVisible)

    // Opening the card window clears any standalone pin: the toolbar's pin
    // button is replaced by the eye/preview toggle, so .pinned has no
    // remaining UI affordance and would only confuse mode bookkeeping.
    cardWindowBridge.$cardWindowVisible
      .filter { $0 }
      .sink { [weak self] _ in
        guard let self, self.mode == .pinned else { return }
        self.mode = .scheduler
        self.show(card: self.currentCard)
      }
      .store(in: &bridgeObservations)
  }

  private func setPreviewCard(_ card: MemoryCard?) {
    if let card {
      mode = .preview(card)
      show(card: card)
    } else if case .preview = mode {
      mode = .scheduler
      refreshScheduledCard()
    }
  }

  private func setHasVisibleManagedWindow(_ visible: Bool) {
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
      // currentCard is EmptyStateCard implies mode is .scheduler / .pinned
      // (preview always carries a MemoryCard), so this also covers .pinned.
      if currentCard is EmptyStateCard {
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
      // .pinned tracks the scheduler's pick (only timeout differs), so it
      // refreshes alongside .scheduler. .preview keeps its locked card.
      if case .preview = mode { break }
      refreshScheduledCard()
    case .didCreateDirectory:
      break
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
    controller.setIdleReminderTimeout(.seconds(settingsStore.idleReminderAnimationSeconds))
    let timeout: Duration?
    switch mode {
    case .preview, .pinned:
      // Both modes hold the notch open indefinitely.
      timeout = nil
    case .scheduler:
      if hasVisibleManagedWindow, settingsStore.skipAutoCollapseOnAnotherWindow {
        timeout = .zero
      } else {
        timeout = card.autoCollapseTimeout(
          memoryCardAutoCollapseSeconds: settingsStore.memoryCardAutoCollapseSeconds)
      }
    }
    controller.setAutoCollapseTimeout(timeout)
    // Preview is the only mode where show() should also force-expand the
    // notch (preview can be triggered while compact). Pin is only ever
    // toggled while the notch is already expanded.
    if case .preview = mode {
      controller.expand()
    }
  }
}
