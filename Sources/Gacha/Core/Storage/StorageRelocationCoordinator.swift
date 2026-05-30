import AppKit
import SwiftUI

/// Drives the storage relocation flow as SwiftUI state. The folder picker stays
/// on `NSOpenPanel` (no SwiftUI equivalent with the same control), but every
/// confirmation/result dialog is published as state and rendered by
/// `SettingsView` through `.alert`, matching the rest of the app's dialogs.
@MainActor
final class StorageRelocationCoordinator: ObservableObject {
  let relocator: StorageRelocator
  let settingsStore: SettingsStore
  let cardCount: () -> Int
  let relaunch: () -> Void

  /// Window the open panel is anchored to. Set by `SettingsView` once it
  /// resolves its hosting `NSWindow`.
  var anchorWindow: NSWindow?

  enum Intent {
    case move
    case adopt
  }

  /// A pending confirmation awaiting the user's choice.
  struct Confirmation: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let confirmTitle: String
    let intent: Intent
    let target: URL
  }

  /// A terminal dialog reporting the outcome of an attempt.
  enum Notice: Identifiable {
    case error(String)
    case success(newPath: String)
    case failure(String)

    var id: String {
      switch self {
      case .error(let message): return "error:\(message)"
      case .success(let path): return "success:\(path)"
      case .failure(let message): return "failure:\(message)"
      }
    }
  }

  @Published var confirmation: Confirmation?
  @Published var notice: Notice?

  init(
    relocator: StorageRelocator,
    settingsStore: SettingsStore,
    cardCount: @escaping () -> Int,
    relaunch: @escaping () -> Void = { AppRelauncher.relaunchAndQuit() }
  ) {
    self.relocator = relocator
    self.settingsStore = settingsStore
    self.cardCount = cardCount
    self.relaunch = relaunch
  }

  /// User explicitly chose "Move…": target must be empty/nonexistent.
  func presentMoveFlow() {
    pickFolder { [weak self] target in
      self?.routeMove(target: target)
    }
  }

  /// User explicitly chose "Use Existing…": target must already be a Gacha root.
  func presentAdoptFlow() {
    pickFolder { [weak self] target in
      self?.routeAdopt(target: target)
    }
  }

  /// Runs the confirmed intent and publishes its outcome as a `Notice`.
  func runConfirmed(_ confirmation: Confirmation) {
    do {
      switch confirmation.intent {
      case .move:
        try relocator.move(to: confirmation.target)
      case .adopt:
        try relocator.adopt(target: confirmation.target)
      }
      notice = .success(newPath: settingsStore.userStorageURL.path)
    } catch {
      notice = .failure(error.localizedDescription)
    }
  }

  func routeMove(target: URL) {
    let state: StorageTargetState
    do {
      state = try relocator.inspect(target: target)
    } catch {
      notice = .error(error.localizedDescription)
      return
    }

    switch state {
    case .fresh:
      confirmation = Confirmation(
        title: StorageStrings.moveTitle(targetName: target.lastPathComponent),
        message: StorageStrings.moveMessage(cardCount: cardCount()),
        confirmTitle: StorageStrings.moveConfirm,
        intent: .move,
        target: target)
    case .adoptable:
      notice = .error(AppStrings.localized("storage.relocate.move.error.adoptable"))
    case .occupied:
      notice = .error(AppStrings.localized("storage.relocate.move.error.occupied"))
    }
  }

  func routeAdopt(target: URL) {
    let state: StorageTargetState
    do {
      state = try relocator.inspect(target: target)
    } catch {
      notice = .error(error.localizedDescription)
      return
    }

    switch state {
    case .adoptable:
      confirmation = Confirmation(
        title: StorageStrings.adoptTitle(targetName: target.lastPathComponent),
        message: StorageStrings.adoptMessage,
        confirmTitle: StorageStrings.adoptConfirm,
        intent: .adopt,
        target: target)
    case .fresh, .occupied:
      notice = .error(AppStrings.localized("storage.relocate.adopt.error.notGachaRoot"))
    }
  }

  private func pickFolder(_ onPick: @escaping (URL) -> Void) {
    guard let window = anchorWindow else {
      preconditionFailure("anchorWindow must be set before invoking storage relocation")
    }

    let panel = NSOpenPanel()
    panel.title = SettingsStrings.storageOpenPanelTitle
    panel.prompt = SettingsStrings.storageOpenPanelPrompt
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    panel.canCreateDirectories = true
    panel.directoryURL = settingsStore.userStorageURL.deletingLastPathComponent()

    panel.beginSheetModal(for: window) { response in
      guard response == .OK, let url = panel.url else {
        return
      }
      onPick(url)
    }
  }
}
