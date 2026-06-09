import SwiftUI

struct CLISettingsSection: View {
  @ObservedObject var environment: AppEnvironment

  @State private var isCLIInstalled: Bool
  @State private var installedCLIPath: String?
  @State private var installMessage: String?
  @State private var isRunning = false
  @State private var showAlert = false

  init(environment: AppEnvironment) {
    self.environment = environment
    let installedURL = environment.installedCLIURL()
    _isCLIInstalled = State(initialValue: installedURL != nil)
    _installedCLIPath = State(initialValue: installedURL?.path)
  }

  var body: some View {
    Section {
      LabeledContent {
        Button(SettingsStrings.cliInstall) {
          installMessage = nil
          isRunning = true
          Task {
            defer { isRunning = false }
            do {
              let result = try await environment.installCLI()
              switch result {
              case .alreadyLatest:
                installMessage = SettingsStrings.cliInstallAlreadyLatest
              case .conflict:
                installMessage = SettingsStrings.cliInstallConflict
              case .success:
                installMessage = SettingsStrings.cliInstallSuccess
              }
            } catch {
              installMessage = SettingsStrings.cliInstallFailed(
                reason: error.localizedDescription)
            }
            refreshCLIInstallState()
            showAlert = true
          }
        }
        .disabled(isRunning || !environment.isMCPServerRunning || isCLIInstalled)
      } label: {
        VStack(alignment: .leading, spacing: 2) {
          Text(SettingsStrings.cliInstall)
          if isCLIInstalled {
            Text(SettingsStrings.cliInstallInstalled(path: installedCLIPath))
              .font(.caption)
              .foregroundStyle(.secondary)
          } else if !environment.isMCPServerRunning {
            Text(SettingsStrings.cliInstallRequiresMCP)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
    } header: {
      Text(SettingsStrings.sectionCLI)
    }
    .alert(
      SettingsStrings.cliInstall,
      isPresented: $showAlert
    ) {
      Button(SettingsStrings.mcpPortErrorDismiss, role: .cancel) {}
    } message: {
      if let message = installMessage { Text(message) }
    }
    .appDialogIcon()
    .onAppear {
      refreshCLIInstallState()
    }
  }

  private func refreshCLIInstallState() {
    let installedURL = environment.installedCLIURL()
    isCLIInstalled = installedURL != nil
    installedCLIPath = installedURL?.path
  }
}
