enum NoticeQueueEvent: Equatable {
  case didEnqueue(NoticeMessage)
  case didRemove(NoticeMessage)
  case didClear([NoticeMessage])
}
