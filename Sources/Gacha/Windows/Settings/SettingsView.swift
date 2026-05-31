import SwiftUI

struct SettingsView: View {
  let directories: AppDirectories
  let launchAtLoginController: LaunchAtLoginController
  let settingsStore: SettingsStore
  let suppressionController: SuppressionController
  @ObservedObject var environment: AppEnvironment
  @ObservedObject var storageRelocationCoordinator: StorageRelocationCoordinator
  @State private var launchAtLoginEnabled: Bool
  @State private var memoryAutoCollapseSeconds: TimeInterval
  @State private var skipCountdownOnAnotherWindow: Bool
  @State private var showKeyboardHints: Bool
  @State private var fullScreenSuppressionEnabled: Bool
  @State private var screenSharingSuppressionEnabled: Bool
  @State private var mcpEnabled: Bool
  @State private var mcpPortInput: Int
  @State private var mcpAppliedPort: Int
  @State private var mcpPortIsInvalid = false
  @State private var mcpError: String?
  @State private var mcpURLHighlighted = false

  init(
    directories: AppDirectories,
    launchAtLoginController: LaunchAtLoginController,
    settingsStore: SettingsStore,
    suppressionController: SuppressionController,
    environment: AppEnvironment,
    storageRelocationCoordinator: StorageRelocationCoordinator
  ) {
    self.directories = directories
    self.launchAtLoginController = launchAtLoginController
    self.settingsStore = settingsStore
    self.suppressionController = suppressionController
    self.environment = environment
    self.storageRelocationCoordinator = storageRelocationCoordinator
    _launchAtLoginEnabled = State(initialValue: settingsStore.launchAtLoginEnabled)
    _memoryAutoCollapseSeconds = State(
      initialValue: settingsStore.memoryAutoCollapseSeconds)
    _skipCountdownOnAnotherWindow = State(
      initialValue: settingsStore.skipCountdownOnAnotherWindow)
    _showKeyboardHints = State(initialValue: settingsStore.showKeyboardHints)
    _fullScreenSuppressionEnabled = State(
      initialValue: settingsStore.fullScreenSuppressionEnabled)
    _screenSharingSuppressionEnabled = State(
      initialValue: settingsStore.screenSharingSuppressionEnabled)
    _mcpEnabled = State(initialValue: settingsStore.mcpEnabled)
    _mcpPortInput = State(initialValue: settingsStore.mcpPort)
    _mcpAppliedPort = State(initialValue: settingsStore.mcpPort)
  }

  var body: some View {
    Form {
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

        Toggle(
          SettingsStrings.fullScreenSuppressionEnabled,
          isOn: Binding(
            get: { fullScreenSuppressionEnabled },
            set: { newValue in
              fullScreenSuppressionEnabled = newValue
              settingsStore.fullScreenSuppressionEnabled = newValue
              suppressionController.reevaluate()
            }))

        Toggle(
          SettingsStrings.screenSharingSuppressionEnabled,
          isOn: Binding(
            get: { screenSharingSuppressionEnabled },
            set: { newValue in
              screenSharingSuppressionEnabled = newValue
              settingsStore.screenSharingSuppressionEnabled = newValue
              suppressionController.reevaluate()
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

      Section {
        Toggle(
          SettingsStrings.mcpEnabled,
          isOn: Binding(
            get: { mcpEnabled },
            set: { newValue in
              mcpEnabled = newValue
              if newValue {
                applyPort()
              } else {
                Task { await applyMCPSettings(enabled: false, port: mcpPortInput) }
              }
            }))

        LabeledContent(SettingsStrings.mcpPort) {
          HStack(spacing: 8) {
            HStack(spacing: 4) {
              TextField("", value: $mcpPortInput, format: .number.grouping(.never))
                .frame(width: 64)
                .multilineTextAlignment(.trailing)
                .overlay(
                  RoundedRectangle(cornerRadius: 4)
                    .stroke(mcpPortIsInvalid ? Color.red : Color.clear, lineWidth: 1)
                )
                .disabled(!mcpEnabled)
              Stepper("", value: $mcpPortInput, in: 1...65535)
                .labelsHidden()
                .disabled(!mcpEnabled)
            }
            Button(SettingsStrings.mcpPortApply) {
              applyPort()
            }
            .disabled(!mcpEnabled || mcpPortInput == mcpAppliedPort)
          }
        }

        LabeledContent(SettingsStrings.mcpURLLabel) {
          VStack(alignment: .trailing, spacing: 8) {
            Text(mcpURL)
              .foregroundStyle(.secondary)
              .padding(.horizontal, 4)
              .background(
                RoundedRectangle(cornerRadius: 4)
                  .fill(mcpURLHighlighted ? Color.accentColor.opacity(0.25) : Color.clear)
                  .animation(.easeOut(duration: 0.4), value: mcpURLHighlighted)
              )
              .textSelection(.enabled)
            HStack(spacing: 8) {
              Button(SettingsStrings.mcpCopyURL) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(mcpURL, forType: .string)
              }
              Button(SettingsStrings.mcpCopyConfig) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(mcpConfig, forType: .string)
              }
            }
          }
        }
        .disabled(!environment.isMCPServerRunning)
      } header: {
        HStack(spacing: 4) {
          Text(SettingsStrings.sectionMCP)
          Image(systemName: environment.isMCPServerRunning ? "network" : "network.slash")
            .foregroundStyle(environment.isMCPServerRunning ? .green : .secondary)
            .imageScale(.small)
        }
      }

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
    .alert(
      SettingsStrings.mcpPortErrorTitle,
      isPresented: Binding(
        get: { mcpError != nil },
        set: { if !$0 { mcpError = nil } }
      )
    ) {
      Button(SettingsStrings.mcpPortErrorDismiss, role: .cancel) {}
    } message: {
      if let mcpError { Text(mcpError) }
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

  private var mcpURL: String {
    "http://127.0.0.1:\(mcpAppliedPort)/mcp"
  }

  private var mcpConfig: String {
    """
    {
      "mcpServers": {
        "gacha": {
          "type": "http",
          "url": "\(mcpURL)"
        }
      }
    }
    """
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

  private func applyPort() {
    guard (1...65535).contains(mcpPortInput) else {
      mcpPortIsInvalid = true
      return
    }
    mcpPortIsInvalid = false
    Task { await applyMCPSettings(enabled: mcpEnabled, port: mcpPortInput) }
  }

  private func applyMCPSettings(enabled: Bool, port: Int) async {
    mcpError = nil
    do {
      try await environment.applyMCPSettings(enabled: enabled, port: port)
      mcpPortInput = port
      mcpAppliedPort = port
      if enabled {
        mcpURLHighlighted = true
        Task {
          try? await Task.sleep(for: .milliseconds(300))
          mcpURLHighlighted = false
        }
      }
    } catch {
      mcpError = SettingsStrings.mcpPortErrorFailed(port: port, reason: error.localizedDescription)
      mcpPortInput = mcpAppliedPort
    }
  }
}
