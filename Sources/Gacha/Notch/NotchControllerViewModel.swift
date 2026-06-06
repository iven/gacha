import Combine

@MainActor
final class NotchControllerViewModel: ObservableObject {
  @Published var isPaused = false
  @Published var isSuppressed = false
  @Published var noticeCount = 0
  @Published var noticeCountPulseTriggerID = 0
  @Published var showsNoticeCount = true
  var handledNoticeCountPulseTriggerID = 0
  var onResumeRequested: (() -> Void)?
}
