import Foundation

enum AppMetadata {
  static let name = "Gacha"
  static let bundleIdentifier = "com.iven.gacha"
  static let applicationSupportDirectoryName = "Gacha"
  static let userStorageDirectoryName = "Gacha"
  static let memoryDirectoryName = "memory"
  static let defaultCategoryDirectoryName = "Uncategorized"
  // Empty marker file written into a Gacha storage root. Its presence is the
  // sole signal used when adopting a directory during relocation.
  static let storageRootMarkerName = ".gacha"
}
