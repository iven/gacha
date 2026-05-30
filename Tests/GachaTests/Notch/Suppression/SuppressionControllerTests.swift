import Testing

@testable import Gacha

private final class StubProbe: SuppressionProbing, @unchecked Sendable {
  var active = false
  func isSuppressingStateActive() -> Bool { active }
}

@MainActor
@Test func suppressedWhenEnabledAndProbeActive() {
  let probe = StubProbe()
  probe.active = true
  let controller = SuppressionController(probe: probe, isEnabled: { true })

  controller.reevaluate()

  #expect(controller.isSuppressed)
}

@MainActor
@Test func notSuppressedWhenFeatureDisabled() {
  let probe = StubProbe()
  probe.active = true
  let controller = SuppressionController(probe: probe, isEnabled: { false })

  controller.reevaluate()

  #expect(!controller.isSuppressed)
}

@MainActor
@Test func notSuppressedWhenProbeInactive() {
  let probe = StubProbe()
  probe.active = false
  let controller = SuppressionController(probe: probe, isEnabled: { true })

  controller.reevaluate()

  #expect(!controller.isSuppressed)
}

@MainActor
@Test func onChangeFiresOnlyOnTransition() {
  let probe = StubProbe()
  var enabled = true
  let controller = SuppressionController(probe: probe, isEnabled: { enabled })
  var changes: [Bool] = []
  controller.onChange = { changes.append($0) }

  probe.active = true
  controller.reevaluate()
  controller.reevaluate()
  enabled = false
  controller.reevaluate()

  #expect(changes == [true, false])
}
