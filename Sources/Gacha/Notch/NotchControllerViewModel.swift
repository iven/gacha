import Combine

@MainActor
final class NotchControllerViewModel: ObservableObject {
  @Published var isPaused = false
  @Published var isSuppressed = false
  @Published var pendingNoticeCount = 0
  @Published var noticeBellPulseTriggerID = 0
  @Published var showsNoticeBell = true
  var handledNoticeBellPulseTriggerID = 0
  var onResumeRequested: (() -> Void)?
}
