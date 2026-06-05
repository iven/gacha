import Foundation

/// One navigable section of the settings window. Drives the sidebar list, the
/// `.id` anchor of each block in the scrolling detail panel, and the shared
/// scroll-spy / selection state. Case order is the on-screen order.
enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
  case startup
  case notch
  case suppression
  case shortcuts
  case storage
  case mcp
  case cli

  var id: String { rawValue }

  var title: String {
    switch self {
    case .startup: return SettingsStrings.sectionStartup
    case .notch: return SettingsStrings.sectionNotch
    case .suppression: return SettingsStrings.sectionSuppression
    case .shortcuts: return SettingsStrings.sectionShortcuts
    case .storage: return SettingsStrings.sectionStorage
    case .mcp: return SettingsStrings.sectionMCP
    case .cli: return SettingsStrings.sectionCLI
    }
  }

  var systemImage: String {
    switch self {
    case .startup: return "power"
    case .notch: return "macwindow"
    case .suppression: return "moon"
    case .shortcuts: return "keyboard"
    case .storage: return "externaldrive"
    case .mcp: return "network"
    case .cli: return "terminal"
    }
  }
}
