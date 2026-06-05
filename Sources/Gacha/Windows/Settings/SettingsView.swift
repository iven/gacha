import AppKit
import SwiftUI

struct SettingsView: View {
  let directories: AppDirectories
  let launchAtLoginController: LaunchAtLoginController
  let settingsStore: SettingsStore
  let suppressionController: SuppressionController
  @ObservedObject var environment: AppEnvironment
  @ObservedObject var storageRelocationCoordinator: StorageRelocationCoordinator

  @State private var activeSection: SettingsSection = .startup
  @State private var scrollTarget: SettingsSection?

  var body: some View {
    NavigationSplitView {
      VStack(spacing: 0) {
        List(selection: sidebarSelection) {
          ForEach(SettingsSection.allCases) { section in
            Label(section.title, systemImage: section.systemImage)
              .tag(section)
          }
        }

        Button(role: .destructive) {
          NSApp.terminate(nil)
        } label: {
          Label(SettingsStrings.quitApp, systemImage: "power")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
        .buttonStyle(.bordered)
        .tint(Color(nsColor: .systemRed))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
      }
      .navigationSplitViewColumnWidth(min: 180, ideal: 200)
    } detail: {
      SettingsDetailPanel(
        directories: directories,
        launchAtLoginController: launchAtLoginController,
        settingsStore: settingsStore,
        suppressionController: suppressionController,
        environment: environment,
        storageRelocationCoordinator: storageRelocationCoordinator,
        activeSection: $activeSection,
        scrollTarget: $scrollTarget
      )
      .navigationTitle(SettingsStrings.windowTitle)
    }
    .frame(minWidth: 720, minHeight: 500)
    .background(
      WindowAccessor { window in
        storageRelocationCoordinator.anchorWindow = window
        configureTitlebar(window)
      }
    )
  }

  /// `Settings` scene windows don't get the unified, full-height titlebar that
  /// `Window` scenes do, so the sidebar toggle lands on its own row below the
  /// title bar instead of inside it. Opt the window into the same chrome the
  /// card window gets automatically.
  private func configureTitlebar(_ window: NSWindow?) {
    guard let window else { return }
    window.styleMask.insert(.fullSizeContentView)
    window.toolbarStyle = .unified
  }

  /// Sidebar selection reflects `activeSection`, which scroll-spy keeps current.
  /// The setter fires only on user click/keyboard and requests a scroll to the
  /// chosen section; scroll-spy writes `activeSection` directly (bypassing this
  /// setter), so there is no feedback loop.
  private var sidebarSelection: Binding<SettingsSection?> {
    Binding(
      get: { activeSection },
      set: { newValue in
        guard let newValue else { return }
        activeSection = newValue
        scrollTarget = newValue
      })
  }
}
