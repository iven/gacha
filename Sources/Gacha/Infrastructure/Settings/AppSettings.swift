import Foundation

struct AppSettings: Equatable {
  var knowledgeAutoCollapseSeconds: TimeInterval

  static let defaults = AppSettings(knowledgeAutoCollapseSeconds: 30)
}
