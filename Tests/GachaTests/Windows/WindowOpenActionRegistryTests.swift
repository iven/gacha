import Testing

@testable import Gacha

@MainActor
@Test func windowOpenActionRegistryOpensRegisteredWindow() {
  let registry = WindowOpenActionRegistry()
  var openedKeys: [AppWindowKey] = []

  registry.register(.cards) {
    openedKeys.append(.cards)
  }
  registry.open(.cards)

  #expect(openedKeys == [.cards])
}

@MainActor
@Test func windowOpenActionRegistryDefersOpenUntilRegistration() {
  let registry = WindowOpenActionRegistry()
  var openedKeys: [AppWindowKey] = []

  registry.open(.settings)
  #expect(openedKeys.isEmpty)

  registry.register(.settings) {
    openedKeys.append(.settings)
  }

  #expect(openedKeys == [.settings])
}

@MainActor
@Test func cardWindowBridgeRoutesOpenThroughRegistry() {
  let registry = WindowOpenActionRegistry()
  let bridge = CardWindowBridge(windowOpenActionRegistry: registry)
  var openedKeys: [AppWindowKey] = []

  registry.register(.cards) {
    openedKeys.append(.cards)
  }
  bridge.requestOpen(editingCardID: "card-1")

  #expect(openedKeys == [.cards])
  #expect(bridge.pendingEditCardID == "card-1")
}
