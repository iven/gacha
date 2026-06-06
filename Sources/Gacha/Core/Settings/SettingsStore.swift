import Foundation

struct SettingsStore {
  static let memoryCardAutoCollapseRange: ClosedRange<TimeInterval> = 0...60
  static let memoryCardAutoCollapseStep: TimeInterval = 1
  static let noticeAutoCollapseRange: ClosedRange<TimeInterval> = 1...10
  static let noticeAutoCollapseStep: TimeInterval = 1
  static let idleReminderAnimationRange: ClosedRange<TimeInterval> = 0...(180 * 60)
  static let idleReminderAnimationStep: TimeInterval = 60

  private enum Key {
    static let userStoragePath = "userStoragePath"
    static let launchAtLoginEnabled = "launchAtLoginEnabled"
    static let memoryCardAutoCollapseSeconds = "memoryCardAutoCollapseSeconds"
    static let noticeAutoCollapseSeconds = "noticeAutoCollapseSeconds"
    static let idleReminderAnimationSeconds = "idleReminderAnimationSeconds"
    static let skipAutoCollapseOnAnotherWindow = "skipAutoCollapseOnAnotherWindow"
    static let showKeyboardHints = "showKeyboardHints"
    static let fullScreenSuppressionEnabled = "fullScreenSuppressionEnabled"
    static let screenSharingSuppressionEnabled = "screenSharingSuppressionEnabled"
    static let focusModeSuppressionEnabled = "focusModeSuppressionEnabled"
    static let mcpEnabled = "mcpEnabled"
    static let mcpPort = "mcpPort"
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
      Key.memoryCardAutoCollapseSeconds: AppSettings.defaultMemoryCardAutoCollapseSeconds,
      Key.noticeAutoCollapseSeconds: AppSettings.defaultNoticeAutoCollapseSeconds,
      Key.idleReminderAnimationSeconds: AppSettings.defaultIdleReminderAnimationSeconds,
      Key.skipAutoCollapseOnAnotherWindow: AppSettings.defaultSkipAutoCollapseOnAnotherWindow,
      Key.showKeyboardHints: AppSettings.defaultShowKeyboardHints,
      Key.fullScreenSuppressionEnabled: AppSettings.defaultFullScreenSuppressionEnabled,
      Key.screenSharingSuppressionEnabled: AppSettings.defaultScreenSharingSuppressionEnabled,
      Key.focusModeSuppressionEnabled: AppSettings.defaultFocusModeSuppressionEnabled,
      Key.mcpEnabled: AppSettings.defaultMCPEnabled,
      Key.mcpPort: AppSettings.defaultMCPPort,
    ])
  }

  static func defaultUserStorageURL(fileManager: FileManager = .default) -> URL {
    fileManager.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    )[0]
    .appendingPathComponent(AppMetadata.applicationSupportDirectoryName, isDirectory: true)
    .appendingPathComponent(AppMetadata.userStorageDirectoryName, isDirectory: true)
  }

  var settings: AppSettings {
    get {
      AppSettings(
        userStorageURL: userStorageURL,
        launchAtLoginEnabled: launchAtLoginEnabled,
        memoryCardAutoCollapseSeconds: memoryCardAutoCollapseSeconds,
        noticeAutoCollapseSeconds: noticeAutoCollapseSeconds,
        idleReminderAnimationSeconds: idleReminderAnimationSeconds,
        skipAutoCollapseOnAnotherWindow: skipAutoCollapseOnAnotherWindow,
        showKeyboardHints: showKeyboardHints,
        fullScreenSuppressionEnabled: fullScreenSuppressionEnabled,
        screenSharingSuppressionEnabled: screenSharingSuppressionEnabled,
        focusModeSuppressionEnabled: focusModeSuppressionEnabled,
        mcpEnabled: mcpEnabled,
        mcpPort: mcpPort)
    }
    nonmutating set {
      userStorageURL = newValue.userStorageURL
      launchAtLoginEnabled = newValue.launchAtLoginEnabled
      memoryCardAutoCollapseSeconds = newValue.memoryCardAutoCollapseSeconds
      noticeAutoCollapseSeconds = newValue.noticeAutoCollapseSeconds
      idleReminderAnimationSeconds = newValue.idleReminderAnimationSeconds
      skipAutoCollapseOnAnotherWindow = newValue.skipAutoCollapseOnAnotherWindow
      showKeyboardHints = newValue.showKeyboardHints
      fullScreenSuppressionEnabled = newValue.fullScreenSuppressionEnabled
      screenSharingSuppressionEnabled = newValue.screenSharingSuppressionEnabled
      focusModeSuppressionEnabled = newValue.focusModeSuppressionEnabled
      mcpEnabled = newValue.mcpEnabled
      mcpPort = newValue.mcpPort
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

  var memoryCardAutoCollapseSeconds: TimeInterval {
    get {
      normalized(
        defaults.double(forKey: Key.memoryCardAutoCollapseSeconds),
        step: Self.memoryCardAutoCollapseStep,
        range: Self.memoryCardAutoCollapseRange)
    }
    nonmutating set {
      defaults.set(
        normalized(
          newValue,
          step: Self.memoryCardAutoCollapseStep,
          range: Self.memoryCardAutoCollapseRange),
        forKey: Key.memoryCardAutoCollapseSeconds)
    }
  }

  var noticeAutoCollapseSeconds: TimeInterval {
    get {
      normalized(
        defaults.double(forKey: Key.noticeAutoCollapseSeconds),
        step: Self.noticeAutoCollapseStep,
        range: Self.noticeAutoCollapseRange)
    }
    nonmutating set {
      defaults.set(
        normalized(
          newValue,
          step: Self.noticeAutoCollapseStep,
          range: Self.noticeAutoCollapseRange),
        forKey: Key.noticeAutoCollapseSeconds)
    }
  }

  var idleReminderAnimationSeconds: TimeInterval {
    get {
      normalized(
        defaults.double(forKey: Key.idleReminderAnimationSeconds),
        step: Self.idleReminderAnimationStep,
        range: Self.idleReminderAnimationRange)
    }
    nonmutating set {
      defaults.set(
        normalized(
          newValue,
          step: Self.idleReminderAnimationStep,
          range: Self.idleReminderAnimationRange),
        forKey: Key.idleReminderAnimationSeconds)
    }
  }

  var skipAutoCollapseOnAnotherWindow: Bool {
    get { defaults.bool(forKey: Key.skipAutoCollapseOnAnotherWindow) }
    nonmutating set { defaults.set(newValue, forKey: Key.skipAutoCollapseOnAnotherWindow) }
  }

  var showKeyboardHints: Bool {
    get { defaults.bool(forKey: Key.showKeyboardHints) }
    nonmutating set { defaults.set(newValue, forKey: Key.showKeyboardHints) }
  }

  var fullScreenSuppressionEnabled: Bool {
    get { defaults.bool(forKey: Key.fullScreenSuppressionEnabled) }
    nonmutating set { defaults.set(newValue, forKey: Key.fullScreenSuppressionEnabled) }
  }

  var screenSharingSuppressionEnabled: Bool {
    get { defaults.bool(forKey: Key.screenSharingSuppressionEnabled) }
    nonmutating set { defaults.set(newValue, forKey: Key.screenSharingSuppressionEnabled) }
  }

  var focusModeSuppressionEnabled: Bool {
    get { defaults.bool(forKey: Key.focusModeSuppressionEnabled) }
    nonmutating set { defaults.set(newValue, forKey: Key.focusModeSuppressionEnabled) }
  }

  var mcpEnabled: Bool {
    get { defaults.bool(forKey: Key.mcpEnabled) }
    nonmutating set { defaults.set(newValue, forKey: Key.mcpEnabled) }
  }

  var mcpPort: Int {
    get { defaults.integer(forKey: Key.mcpPort) }
    nonmutating set { defaults.set(newValue, forKey: Key.mcpPort) }
  }

  private func normalized(
    _ value: TimeInterval,
    step: TimeInterval,
    range: ClosedRange<TimeInterval>
  ) -> TimeInterval {
    let steppedValue = (value / step).rounded() * step
    return min(max(steppedValue, range.lowerBound), range.upperBound)
  }
}
