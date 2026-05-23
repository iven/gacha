import Foundation

struct AppSettings: Equatable {
  var userStorageURL: URL
  var launchAtLoginEnabled: Bool
  var knowledgeAutoCollapseSeconds: TimeInterval

  static let defaultLaunchAtLoginEnabled = true
  static let defaultKnowledgeAutoCollapseSeconds: TimeInterval = 30

  static func defaults(userStorageURL: URL) -> AppSettings {
    AppSettings(
      userStorageURL: userStorageURL,
      launchAtLoginEnabled: defaultLaunchAtLoginEnabled,
      knowledgeAutoCollapseSeconds: defaultKnowledgeAutoCollapseSeconds)
  }
}
