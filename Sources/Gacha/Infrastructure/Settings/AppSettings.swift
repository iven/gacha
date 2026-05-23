import Foundation

struct AppSettings: Codable, Equatable {
  var knowledgeAutoCollapseSeconds: TimeInterval

  static let defaults = AppSettings(knowledgeAutoCollapseSeconds: 30)
}
