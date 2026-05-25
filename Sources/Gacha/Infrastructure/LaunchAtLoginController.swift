import Foundation
import ServiceManagement

enum LaunchAtLoginStatus: Equatable {
  case notRegistered
  case enabled
  case requiresApproval
  case notFound
  case unavailable
}

protocol LaunchAtLoginService: AnyObject {
  var status: LaunchAtLoginStatus { get }

  func openSystemSettingsLoginItems()
  func register() throws
  func unregister() throws
}

struct LaunchAtLoginController {
  private let service: LaunchAtLoginService

  init(service: LaunchAtLoginService = MainAppLaunchAtLoginService()) {
    self.service = service
  }

  @discardableResult
  func synchronize(enabled: Bool) throws -> LaunchAtLoginStatus {
    if enabled {
      return try enable()
    }

    return try disable()
  }

  func openSystemSettingsLoginItems() {
    service.openSystemSettingsLoginItems()
  }

  private func enable() throws -> LaunchAtLoginStatus {
    switch service.status {
    case .enabled, .requiresApproval, .unavailable:
      return service.status
    case .notRegistered, .notFound:
      try service.register()
      return service.status
    }
  }

  private func disable() throws -> LaunchAtLoginStatus {
    switch service.status {
    case .notRegistered, .notFound, .unavailable:
      return service.status
    case .enabled, .requiresApproval:
      try service.unregister()
      return service.status
    }
  }
}

private final class MainAppLaunchAtLoginService: LaunchAtLoginService {
  private let service = SMAppService.mainApp

  var status: LaunchAtLoginStatus {
    guard Self.isRunningFromApplicationBundle else {
      return .unavailable
    }

    switch service.status {
    case .notRegistered:
      return .notRegistered
    case .enabled:
      return .enabled
    case .requiresApproval:
      return .requiresApproval
    case .notFound:
      return .notFound
    @unknown default:
      return .notFound
    }
  }

  func register() throws {
    guard Self.isRunningFromApplicationBundle else {
      return
    }

    try service.register()
  }

  func unregister() throws {
    guard Self.isRunningFromApplicationBundle else {
      return
    }

    try service.unregister()
  }

  func openSystemSettingsLoginItems() {
    SMAppService.openSystemSettingsLoginItems()
  }

  private static var isRunningFromApplicationBundle: Bool {
    Bundle.main.bundleURL.pathExtension == "app"
  }
}
