import OSLog

enum AppLogger {
  static let app = Logger(subsystem: AppMetadata.bundleIdentifier, category: "app")
}
