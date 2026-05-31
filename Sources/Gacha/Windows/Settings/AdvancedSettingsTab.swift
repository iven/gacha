import SwiftUI

struct AdvancedSettingsTab: View {
  let directories: AppDirectories
  @ObservedObject var storageRelocationCoordinator: StorageRelocationCoordinator

  var body: some View {
    Form {
      StorageSettingsSection(
        directories: directories,
        storageRelocationCoordinator: storageRelocationCoordinator)
    }
    .formStyle(.grouped)
    .scrollDisabled(true)
    .frame(width: 520)
    .fixedSize(horizontal: false, vertical: true)
  }
}
