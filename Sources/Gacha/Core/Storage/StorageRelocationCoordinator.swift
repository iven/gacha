import AppKit

@MainActor
final class StorageRelocationCoordinator {
  let relocator: StorageRelocator
  let settingsStore: SettingsStore
  let cardCount: () -> Int
  let relaunch: () -> Void

  /// The window sheets are anchored to. Set externally by the Settings scene
  /// once it has resolved its hosting NSWindow; falls back to app-modal when
  /// nil (e.g. before the Settings window has materialized its NSWindow).
  var anchorWindow: NSWindow?

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
    Task { await runMoveFlow() }
  }

  /// User explicitly chose "Use Existing…": target must already be a Gacha root.
  func presentAdoptFlow() {
    Task { await runAdoptFlow() }
  }

  private func runMoveFlow() async {
    guard let target = await pickFolder() else {
      return
    }

    let state: StorageTargetState
    do {
      state = try relocator.inspect(target: target)
    } catch {
      await presentError(error.localizedDescription)
      return
    }

    switch state {
    case .fresh:
      if await confirm(
        title: StorageStrings.moveTitle(targetName: target.lastPathComponent),
        message: StorageStrings.moveMessage(cardCount: cardCount()),
        confirmTitle: StorageStrings.moveConfirm)
      {
        do {
          try relocator.move(to: target)
          await presentSuccessAndRelaunch()
        } catch {
          await presentFailure(error.localizedDescription)
        }
      }
    case .adoptable:
      await presentError(AppStrings.localized("storage.relocate.move.error.adoptable"))
    case .occupied:
      await presentError(AppStrings.localized("storage.relocate.move.error.occupied"))
    }
  }

  private func runAdoptFlow() async {
    guard let target = await pickFolder() else {
      return
    }

    let state: StorageTargetState
    do {
      state = try relocator.inspect(target: target)
    } catch {
      await presentError(error.localizedDescription)
      return
    }

    switch state {
    case .adoptable:
      if await confirm(
        title: StorageStrings.adoptTitle(targetName: target.lastPathComponent),
        message: StorageStrings.adoptMessage,
        confirmTitle: StorageStrings.adoptConfirm)
      {
        do {
          try relocator.adopt(target: target)
          await presentSuccessAndRelaunch()
        } catch {
          await presentFailure(error.localizedDescription)
        }
      }
    case .fresh, .occupied:
      await presentError(AppStrings.localized("storage.relocate.adopt.error.notGachaRoot"))
    }
  }

  private func pickFolder() async -> URL? {
    let panel = NSOpenPanel()
    panel.title = SettingsStrings.storageOpenPanelTitle
    panel.prompt = SettingsStrings.storageOpenPanelPrompt
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    panel.canCreateDirectories = true
    panel.directoryURL = settingsStore.userStorageURL.deletingLastPathComponent()

    let response = await runOpenPanel(panel)
    return response == .OK ? panel.url : nil
  }

  private func runOpenPanel(_ panel: NSOpenPanel) async -> NSApplication.ModalResponse {
    guard let window = anchorWindow else {
      preconditionFailure("anchorWindow must be set before invoking storage relocation")
    }
    return await withCheckedContinuation { continuation in
      panel.beginSheetModal(for: window) { response in
        continuation.resume(returning: response)
      }
    }
  }

  private func confirm(title: String, message: String, confirmTitle: String) async -> Bool {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = message
    alert.addButton(withTitle: confirmTitle)
    alert.addButton(withTitle: StorageStrings.cancel)
    alert.alertStyle = .warning
    alert.icon = NSImage(
      systemSymbolName: "externaldrive",
      accessibilityDescription: nil)
    return await runAlert(alert) == .alertFirstButtonReturn
  }

  private func presentError(_ message: String) async {
    let alert = NSAlert()
    alert.messageText = StorageStrings.errorTitle
    alert.informativeText = message
    alert.alertStyle = .warning
    alert.icon = NSImage(
      systemSymbolName: "exclamationmark.triangle",
      accessibilityDescription: nil)
    alert.addButton(withTitle: StorageStrings.errorDismiss)
    _ = await runAlert(alert)
  }

  private func presentSuccessAndRelaunch() async {
    let alert = NSAlert()
    alert.messageText = StorageStrings.successTitle
    alert.informativeText = StorageStrings.successMessage(
      newPath: settingsStore.userStorageURL.path)
    alert.alertStyle = .informational
    alert.icon = NSImage(
      systemSymbolName: "checkmark.circle",
      accessibilityDescription: nil)
    alert.addButton(withTitle: StorageStrings.successRelaunch)
    _ = await runAlert(alert)
    relaunch()
  }

  private func presentFailure(_ message: String) async {
    let alert = NSAlert()
    alert.messageText = StorageStrings.failureTitle
    alert.informativeText = message
    alert.alertStyle = .critical
    alert.icon = NSImage(
      systemSymbolName: "xmark.octagon",
      accessibilityDescription: nil)
    alert.addButton(withTitle: StorageStrings.failureDismiss)
    _ = await runAlert(alert)
  }

  private func runAlert(_ alert: NSAlert) async -> NSApplication.ModalResponse {
    guard let window = anchorWindow else {
      preconditionFailure("anchorWindow must be set before invoking storage relocation")
    }
    return await withCheckedContinuation { continuation in
      alert.beginSheetModal(for: window) { response in
        continuation.resume(returning: response)
      }
    }
  }
}
