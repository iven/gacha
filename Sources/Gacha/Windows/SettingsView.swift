import SwiftUI

struct SettingsView: View {
  let directories: AppDirectories
  let settingsStore: SettingsStore
  @State private var knowledgeAutoCollapseSeconds: TimeInterval

  init(directories: AppDirectories, settingsStore: SettingsStore) {
    self.directories = directories
    self.settingsStore = settingsStore
    _knowledgeAutoCollapseSeconds = State(
      initialValue: settingsStore.knowledgeAutoCollapseSeconds)
  }

  var body: some View {
    TabView {
      overviewTab
        .tabItem {
          Text(SettingsStrings.overviewTab)
        }

      cardsTab
        .tabItem {
          Text(SettingsStrings.cardsTab)
        }

      advancedTab
        .tabItem {
          Text(SettingsStrings.advancedTab)
        }
    }
    .frame(minWidth: 560, minHeight: 340)
  }

  private var overviewTab: some View {
    settingsPane {
      settingsRow(SettingsStrings.storageLocation) {
        Text(directories.userStorageURL.path)
          .lineLimit(1)
          .truncationMode(.middle)
          .textSelection(.enabled)
      }

      settingsRow(SettingsStrings.autoCollapse) {
        HStack {
          Slider(
            value: Binding(
              get: {
                knowledgeAutoCollapseSeconds
              },
              set: { newValue in
                knowledgeAutoCollapseSeconds = newValue
                settingsStore.knowledgeAutoCollapseSeconds = newValue
              }),
            in: SettingsStore.knowledgeAutoCollapseRange,
            step: SettingsStore.knowledgeAutoCollapseStep)
          Text("\(Int(knowledgeAutoCollapseSeconds)) s")
            .monospacedDigit()
            .frame(width: 48, alignment: .trailing)
        }
        .frame(width: 300)
      }
    }
  }

  private var cardsTab: some View {
    settingsPane {
    }
  }

  private var advancedTab: some View {
    settingsPane {
      settingsRow(SettingsStrings.dataDirectory) {
        Text(directories.applicationSupportURL.path)
          .lineLimit(1)
          .truncationMode(.middle)
          .textSelection(.enabled)
      }
    }
  }

  private func settingsPane<Content: View>(
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      content()
      Spacer(minLength: 0)
    }
    .frame(width: 470, alignment: .topLeading)
    .padding(.top, 28)
    .padding(.bottom, 24)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }

  private func settingsRow<Content: View>(
    _ title: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    HStack(alignment: .center, spacing: 12) {
      Text(title)
        .frame(width: 96, alignment: .trailing)

      content()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
