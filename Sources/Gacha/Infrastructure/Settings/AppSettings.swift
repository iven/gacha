import Foundation

struct AppSettings: Equatable {
  var userStorageURL: URL
  var knowledgeAutoCollapseSeconds: TimeInterval

  static let defaultKnowledgeAutoCollapseSeconds: TimeInterval = 30

  static func defaults(userStorageURL: URL) -> AppSettings {
    AppSettings(
      userStorageURL: userStorageURL,
      knowledgeAutoCollapseSeconds: defaultKnowledgeAutoCollapseSeconds)
  }
}
