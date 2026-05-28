import Foundation

struct SettingsStore {
  static let memoryAutoCollapseRange: ClosedRange<TimeInterval> = 1...60
  static let memoryAutoCollapseStep: TimeInterval = 1

  private enum Key {
    static let userStoragePath = "userStoragePath"
    static let launchAtLoginEnabled = "launchAtLoginEnabled"
    static let memoryAutoCollapseSeconds = "memoryAutoCollapseSeconds"
    static let skipCountdownOnAnotherWindow = "skipCountdownOnAnotherWindow"
    static let showKeyboardHints = "showKeyboardHints"
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
      Key.launchAtLoginEnabled: AppSettings.defaultLaunchAtLoginEnabled,
      Key.memoryAutoCollapseSeconds: AppSettings.defaultMemoryAutoCollapseSeconds,
      Key.skipCountdownOnAnotherWindow: AppSettings.defaultSkipCountdownOnAnotherWindow,
      Key.showKeyboardHints: AppSettings.defaultShowKeyboardHints,
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
        launchAtLoginEnabled: launchAtLoginEnabled,
        memoryAutoCollapseSeconds: memoryAutoCollapseSeconds,
        skipCountdownOnAnotherWindow: skipCountdownOnAnotherWindow,
        showKeyboardHints: showKeyboardHints)
    }
    nonmutating set {
      userStorageURL = newValue.userStorageURL
      launchAtLoginEnabled = newValue.launchAtLoginEnabled
      memoryAutoCollapseSeconds = newValue.memoryAutoCollapseSeconds
      skipCountdownOnAnotherWindow = newValue.skipCountdownOnAnotherWindow
      showKeyboardHints = newValue.showKeyboardHints
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

  var launchAtLoginEnabled: Bool {
    get {
      defaults.bool(forKey: Key.launchAtLoginEnabled)
    }
    nonmutating set {
      defaults.set(newValue, forKey: Key.launchAtLoginEnabled)
    }
  }

  var memoryAutoCollapseSeconds: TimeInterval {
    get {
      normalizedMemoryAutoCollapseSeconds(
        defaults.double(forKey: Key.memoryAutoCollapseSeconds))
    }
    nonmutating set {
      defaults.set(
        normalizedMemoryAutoCollapseSeconds(newValue),
        forKey: Key.memoryAutoCollapseSeconds)
    }
  }

  var skipCountdownOnAnotherWindow: Bool {
    get { defaults.bool(forKey: Key.skipCountdownOnAnotherWindow) }
    nonmutating set { defaults.set(newValue, forKey: Key.skipCountdownOnAnotherWindow) }
  }

  var showKeyboardHints: Bool {
    get { defaults.bool(forKey: Key.showKeyboardHints) }
    nonmutating set { defaults.set(newValue, forKey: Key.showKeyboardHints) }
  }

  private func normalizedMemoryAutoCollapseSeconds(
    _ value: TimeInterval
  ) -> TimeInterval {
    let steppedValue =
      (value / Self.memoryAutoCollapseStep).rounded()
      * Self.memoryAutoCollapseStep
    return min(
      max(steppedValue, Self.memoryAutoCollapseRange.lowerBound),
      Self.memoryAutoCollapseRange.upperBound)
  }
}
