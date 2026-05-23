import Foundation

struct SettingsStore {
  static let knowledgeAutoCollapseRange: ClosedRange<TimeInterval> = 5...120
  static let knowledgeAutoCollapseStep: TimeInterval = 5

  private enum Key {
    static let userStoragePath = "userStoragePath"
    static let knowledgeAutoCollapseSeconds = "knowledgeAutoCollapseSeconds"
  }

  private let defaults: UserDefaults
  private let defaultUserStorageURL: URL

  init(
    defaults: UserDefaults = .standard,
    defaultUserStorageURL: URL = Self.defaultUserStorageURL()
  ) {
    self.defaults = defaults
    self.defaultUserStorageURL = defaultUserStorageURL
    defaults.register(defaults: [
      Key.knowledgeAutoCollapseSeconds: AppSettings.defaultKnowledgeAutoCollapseSeconds
    ])
  }

  static func defaultUserStorageURL(fileManager: FileManager = .default) -> URL {
    fileManager.urls(
      for: .documentDirectory,
      in: .userDomainMask
    )[0].appendingPathComponent(AppMetadata.userStorageDirectoryName, isDirectory: true)
  }

  var settings: AppSettings {
    get {
      AppSettings(
        userStorageURL: userStorageURL,
        knowledgeAutoCollapseSeconds: knowledgeAutoCollapseSeconds)
    }
    nonmutating set {
      userStorageURL = newValue.userStorageURL
      knowledgeAutoCollapseSeconds = newValue.knowledgeAutoCollapseSeconds
    }
  }

  var userStorageURL: URL {
    get {
      guard let path = defaults.string(forKey: Key.userStoragePath) else {
        return defaultUserStorageURL
      }

      return URL(fileURLWithPath: path, isDirectory: true)
    }
    nonmutating set {
      defaults.set(newValue.path, forKey: Key.userStoragePath)
    }
  }

  var knowledgeAutoCollapseSeconds: TimeInterval {
    get {
      normalizedKnowledgeAutoCollapseSeconds(
        defaults.double(forKey: Key.knowledgeAutoCollapseSeconds))
    }
    nonmutating set {
      defaults.set(
        normalizedKnowledgeAutoCollapseSeconds(newValue),
        forKey: Key.knowledgeAutoCollapseSeconds)
    }
  }

  private func normalizedKnowledgeAutoCollapseSeconds(
    _ value: TimeInterval
  ) -> TimeInterval {
    let steppedValue =
      (value / Self.knowledgeAutoCollapseStep).rounded()
      * Self.knowledgeAutoCollapseStep
    return min(
      max(steppedValue, Self.knowledgeAutoCollapseRange.lowerBound),
      Self.knowledgeAutoCollapseRange.upperBound)
  }
}
