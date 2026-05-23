import SwiftUI

struct SettingsView: View {
  let directories: AppDirectories

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
    .padding(20)
    .frame(minWidth: 520, minHeight: 320)
  }

  private var overviewTab: some View {
    Form {
      LabeledContent(SettingsStrings.storageLocation) {
        Text(directories.userStorageURL.path)
          .textSelection(.enabled)
      }

      LabeledContent(SettingsStrings.autoCollapse) {
        Text("\(Int(AppSettings.defaults.knowledgeAutoCollapseSeconds)) s")
      }
    }
  }

  private var cardsTab: some View {
    VStack {
    }
  }

  private var advancedTab: some View {
    Form {
      LabeledContent(SettingsStrings.dataDirectory) {
        Text(directories.applicationSupportURL.path)
          .textSelection(.enabled)
      }
    }
  }
}
