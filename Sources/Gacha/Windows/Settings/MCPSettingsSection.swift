import SwiftUI

struct MCPSettingsSection: View {
  @ObservedObject var environment: AppEnvironment
  let settingsStore: SettingsStore

  @State private var mcpEnabled: Bool
  @State private var mcpPortInput: Int
  @State private var mcpAppliedPort: Int
  @State private var mcpPortIsInvalid = false
  @State private var mcpError: String?
  @State private var mcpURLHighlighted = false

  init(environment: AppEnvironment, settingsStore: SettingsStore) {
    self.environment = environment
    self.settingsStore = settingsStore
    _mcpEnabled = State(initialValue: settingsStore.mcpEnabled)
    _mcpPortInput = State(initialValue: settingsStore.mcpPort)
    _mcpAppliedPort = State(initialValue: settingsStore.mcpPort)
  }

  var body: some View {
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
