import Foundation

struct SettingsStore {
  static let knowledgeAutoCollapseRange: ClosedRange<TimeInterval> = 5...120
  static let knowledgeAutoCollapseStep: TimeInterval = 5

  private enum Key {
    static let knowledgeAutoCollapseSeconds = "knowledgeAutoCollapseSeconds"
  }

  private let defaults: UserDefaults

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    defaults.register(defaults: [
      Key.knowledgeAutoCollapseSeconds: AppSettings.defaults.knowledgeAutoCollapseSeconds
    ])
  }

  var settings: AppSettings {
    get {
      AppSettings(knowledgeAutoCollapseSeconds: knowledgeAutoCollapseSeconds)
    }
    nonmutating set {
      knowledgeAutoCollapseSeconds = newValue.knowledgeAutoCollapseSeconds
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
