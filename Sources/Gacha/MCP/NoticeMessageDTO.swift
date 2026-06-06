import Foundation

struct NoticeMessageDTO: Encodable {
  let markdown: String
  let createdAt: Date

  init(_ message: NoticeMessage) {
    markdown = message.markdown
    createdAt = message.createdAt
  }
}
