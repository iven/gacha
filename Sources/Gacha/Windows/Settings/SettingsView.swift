import SwiftUI

struct SettingsView: View {
  let directories: AppDirectories
  let launchAtLoginController: LaunchAtLoginController
  let settingsStore: SettingsStore
  @ObservedObject var storageRelocationCoordinator: StorageRelocationCoordinator
  @State private var launchAtLoginEnabled: Bool
  @State private var memoryAutoCollapseSeconds: TimeInterval
  @State private var skipCountdownOnAnotherWindow: Bool
  @State private var showKeyboardHints: Bool

  init(
    directories: AppDirectories,
    launchAtLoginController: LaunchAtLoginController,
    settingsStore: SettingsStore,
    storageRelocationCoordinator: StorageRelocationCoordinator
  ) {
    self.directories = directories
    self.launchAtLoginController = launchAtLoginController
    self.settingsStore = settingsStore
    self.storageRelocationCoordinator = storageRelocationCoordinator
    _launchAtLoginEnabled = State(initialValue: settingsStore.launchAtLoginEnabled)
    _memoryAutoCollapseSeconds = State(
      initialValue: settingsStore.memoryAutoCollapseSeconds)
    _skipCountdownOnAnotherWindow = State(
      initialValue: settingsStore.skipCountdownOnAnotherWindow)
    _showKeyboardHints = State(initialValue: settingsStore.showKeyboardHints)
  }

  var body: some View {
    Form {
      Section(SettingsStrings.sectionStorage) {
        LabeledContent(SettingsStrings.storageLocation) {
          VStack(alignment: .trailing, spacing: 8) {
            Text(directories.userStorageURL.path)
              .lineLimit(1)
              .truncationMode(.middle)
              .textSelection(.enabled)
              .foregroundStyle(.secondary)
            HStack(spacing: 8) {
              Button(SettingsStrings.storageLocationMove) {
                storageRelocationCoordinator.presentMoveFlow()
              }
              Button(SettingsStrings.storageLocationAdopt) {
                storageRelocationCoordinator.presentAdoptFlow()
              }
            }
          }
        }
      }

      Section(SettingsStrings.sectionGeneral) {
        Toggle(
          SettingsStrings.launchAtLogin,
          isOn: Binding(
            get: { launchAtLoginEnabled },
            set: { setLaunchAtLoginEnabled($0) }))
      }

      Section(SettingsStrings.sectionNotch) {
        Toggle(
          SettingsStrings.showKeyboardHints,
          isOn: Binding(
            get: { showKeyboardHints },
            set: { newValue in
              showKeyboardHints = newValue
              settingsStore.showKeyboardHints = newValue
            }))

        Toggle(
          SettingsStrings.skipCountdownOnAnotherWindow,
          isOn: Binding(
            get: { skipCountdownOnAnotherWindow },
            set: { newValue in
              skipCountdownOnAnotherWindow = newValue
              settingsStore.skipCountdownOnAnotherWindow = newValue
            }))
      }

      Section(SettingsStrings.sectionMemoryCards) {
        LabeledContent(SettingsStrings.collapseCountdown) {
          HStack(spacing: 8) {
            Slider(
              value: Binding(
                get: { memoryAutoCollapseSeconds },
                set: { newValue in
                  memoryAutoCollapseSeconds = newValue
                  settingsStore.memoryAutoCollapseSeconds = newValue
                }),
              in: SettingsStore.memoryAutoCollapseRange,
              step: SettingsStore.memoryAutoCollapseStep)
            Text("\(Int(memoryAutoCollapseSeconds))\(SettingsStrings.collapseCountdownUnit)")
              .foregroundStyle(.secondary)
              .monospacedDigit()
              .frame(width: 36, alignment: .trailing)
          }
        }
      }
    }
    .formStyle(.grouped)
    .scrollDisabled(true)
    .frame(width: 520)
    .fixedSize(horizontal: false, vertical: true)
    .background(
      WindowAccessor { window in
        storageRelocationCoordinator.anchorWindow = window
      }
    )
    .alert(
      Text(storageRelocationCoordinator.confirmation?.title ?? ""),
      isPresented: confirmationIsPresented,
      presenting: storageRelocationCoordinator.confirmation
    ) { confirmation in
      Button(confirmation.confirmTitle) {
        storageRelocationCoordinator.runConfirmed(confirmation)
      }
      Button(StorageStrings.cancel, role: .cancel) {}
    } message: { confirmation in
      Text(confirmation.message)
    }
    .alert(
      Text(noticeTitle),
      isPresented: noticeIsPresented,
      presenting: storageRelocationCoordinator.notice
    ) { notice in
      noticeActions(notice)
    } message: { notice in
      Text(noticeMessage(notice))
    }
  }

  private var confirmationIsPresented: Binding<Bool> {
    Binding(
      get: { storageRelocationCoordinator.confirmation != nil },
      set: { if !$0 { storageRelocationCoordinator.confirmation = nil } })
  }

  private var noticeIsPresented: Binding<Bool> {
    Binding(
      get: { storageRelocationCoordinator.notice != nil },
      set: { if !$0 { storageRelocationCoordinator.notice = nil } })
  }

  private var noticeTitle: String {
    switch storageRelocationCoordinator.notice {
    case .error: return StorageStrings.errorTitle
    case .success: return StorageStrings.successTitle
    case .failure: return StorageStrings.failureTitle
    case nil: return ""
    }
  }

  @ViewBuilder
  private func noticeActions(
    _ notice: StorageRelocationCoordinator.Notice
  ) -> some View {
    switch notice {
    case .error:
      Button(StorageStrings.errorDismiss) {}
    case .success:
      Button(StorageStrings.successRelaunch) {
        storageRelocationCoordinator.relaunch()
      }
    case .failure:
      Button(StorageStrings.failureDismiss) {}
    }
  }

  private func noticeMessage(
    _ notice: StorageRelocationCoordinator.Notice
  ) -> String {
    switch notice {
    case .error(let message): return message
    case .success(let path): return StorageStrings.successMessage(newPath: path)
    case .failure(let message): return message
    }
  }

  private func setLaunchAtLoginEnabled(_ enabled: Bool) {
    launchAtLoginEnabled = enabled
    settingsStore.launchAtLoginEnabled = enabled

    do {
      let status = try launchAtLoginController.synchronize(enabled: enabled)
      if enabled && status == .requiresApproval {
        launchAtLoginController.openSystemSettingsLoginItems()
      }
    } catch {
      AppLogger.app.warning("Failed to synchronize launch at login: \(error.localizedDescription)")
    }
  }
}
