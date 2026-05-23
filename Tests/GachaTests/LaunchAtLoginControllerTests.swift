import Foundation
import Testing

@testable import Gacha

@Test func launchAtLoginControllerRegistersWhenEnabled() throws {
  let service = FakeLaunchAtLoginService(status: .notRegistered)
  let controller = LaunchAtLoginController(service: service)

  let status = try controller.synchronize(enabled: true)

  #expect(status == .enabled)
  #expect(service.registerCallCount == 1)
  #expect(service.unregisterCallCount == 0)
}

@Test func launchAtLoginControllerDoesNotRegisterWhenApprovalIsRequired() throws {
  let service = FakeLaunchAtLoginService(status: .requiresApproval)
  let controller = LaunchAtLoginController(service: service)

  let status = try controller.synchronize(enabled: true)

  #expect(status == .requiresApproval)
  #expect(service.registerCallCount == 0)
}

@Test func launchAtLoginControllerDoesNotRegisterWhenUnavailable() throws {
  let service = FakeLaunchAtLoginService(status: .unavailable)
  let controller = LaunchAtLoginController(service: service)

  let status = try controller.synchronize(enabled: true)

  #expect(status == .unavailable)
  #expect(service.registerCallCount == 0)
}

@Test func launchAtLoginControllerUnregistersWhenDisabled() throws {
  let service = FakeLaunchAtLoginService(status: .enabled)
  let controller = LaunchAtLoginController(service: service)

  let status = try controller.synchronize(enabled: false)

  #expect(status == .notRegistered)
  #expect(service.registerCallCount == 0)
  #expect(service.unregisterCallCount == 1)
}

@Test func launchAtLoginControllerDoesNotUnregisterWhenAlreadyDisabled() throws {
  let service = FakeLaunchAtLoginService(status: .notRegistered)
  let controller = LaunchAtLoginController(service: service)

  let status = try controller.synchronize(enabled: false)

  #expect(status == .notRegistered)
  #expect(service.unregisterCallCount == 0)
}

@Test func launchAtLoginControllerOpensSystemSettings() {
  let service = FakeLaunchAtLoginService(status: .requiresApproval)
  let controller = LaunchAtLoginController(service: service)

  controller.openSystemSettingsLoginItems()

  #expect(service.openSystemSettingsCallCount == 1)
}

private final class FakeLaunchAtLoginService: LaunchAtLoginService {
  var status: LaunchAtLoginStatus
  var registerCallCount = 0
  var unregisterCallCount = 0
  var openSystemSettingsCallCount = 0

  init(status: LaunchAtLoginStatus) {
    self.status = status
  }

  func register() {
    registerCallCount += 1
    status = .enabled
  }

  func unregister() {
    unregisterCallCount += 1
    status = .notRegistered
  }

  func openSystemSettingsLoginItems() {
    openSystemSettingsCallCount += 1
  }
}
