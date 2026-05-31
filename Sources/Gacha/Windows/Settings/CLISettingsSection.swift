import SwiftUI

struct CLISettingsSection: View {
  @ObservedObject var environment: AppEnvironment

  @State private var isCLIInstalled: Bool
  @State private var installMessage: String?
  @State private var isRunning = false
  @State private var showAlert = false

  init(environment: AppEnvironment) {
    self.environment = environment
    _isCLIInstalled = State(initialValue: environment.isCLIInstalled())
  }

  var body: some View {
    Section {
      LabeledContent(SettingsStrings.cliInstall) {
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
            isCLIInstalled = environment.isCLIInstalled()
            showAlert = true
          }
        }
        .disabled(isRunning || !environment.isMCPServerRunning || isCLIInstalled)
      }
    } header: {
      Text(SettingsStrings.sectionCLI)
    } footer: {
      if isCLIInstalled {
        Text(SettingsStrings.cliInstallInstalled)
      } else if !environment.isMCPServerRunning {
        Text(SettingsStrings.cliInstallRequiresMCP)
      }
    }
    .alert(
      SettingsStrings.cliInstall,
      isPresented: $showAlert
    ) {
      Button(SettingsStrings.mcpPortErrorDismiss, role: .cancel) {}
    } message: {
      if let message = installMessage { Text(message) }
    }
  }
}
