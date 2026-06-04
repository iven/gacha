import SwiftUI

struct StorageSettingsSection: View {
  let directories: AppDirectories
  @ObservedObject var storageRelocationCoordinator: StorageRelocationCoordinator

  var body: some View {
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
    .appDialogIcon()
    .alert(
      Text(noticeTitle),
      isPresented: noticeIsPresented,
      presenting: storageRelocationCoordinator.notice
    ) { notice in
      noticeActions(notice)
    } message: { notice in
      Text(noticeMessage(notice))
    }
    .appDialogIcon()
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
  private func noticeActions(_ notice: StorageRelocationCoordinator.Notice) -> some View {
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

  private func noticeMessage(_ notice: StorageRelocationCoordinator.Notice) -> String {
    switch notice {
    case .error(let message): return message
    case .success(let path): return StorageStrings.successMessage(newPath: path)
    case .failure(let message): return message
    }
  }
}
