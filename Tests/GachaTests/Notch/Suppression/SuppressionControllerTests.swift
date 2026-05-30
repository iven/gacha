import Testing

@testable import Gacha

private final class StubProbe: SuppressionProbing, @unchecked Sendable {
  var active = false
  func isSuppressingStateActive() -> Bool { active }
}

@MainActor
private func makeController(
  probe: StubProbe,
  isEnabled: @escaping () -> Bool
) -> SuppressionController {
  SuppressionController(sources: [
    SuppressionController.Source(probe: probe, isEnabled: isEnabled)
  ])
}

@MainActor
@Test func suppressedWhenEnabledAndProbeActive() {
  let probe = StubProbe()
  probe.active = true
  let controller = makeController(probe: probe, isEnabled: { true })

  controller.reevaluate()

  #expect(controller.isSuppressed)
}

@MainActor
@Test func notSuppressedWhenFeatureDisabled() {
  let probe = StubProbe()
  probe.active = true
  let controller = makeController(probe: probe, isEnabled: { false })

  controller.reevaluate()

  #expect(!controller.isSuppressed)
}

@MainActor
@Test func notSuppressedWhenProbeInactive() {
  let probe = StubProbe()
  probe.active = false
  let controller = makeController(probe: probe, isEnabled: { true })

  controller.reevaluate()

  #expect(!controller.isSuppressed)
}

@MainActor
@Test func onChangeFiresOnlyOnTransition() {
  let probe = StubProbe()
  var enabled = true
  let controller = makeController(probe: probe, isEnabled: { enabled })
  var changes: [Bool] = []
  controller.onChange = { changes.append($0) }

  probe.active = true
  controller.reevaluate()
  controller.reevaluate()
  enabled = false
  controller.reevaluate()

  #expect(changes == [true, false])
}

@MainActor
@Test func suppressedWhenAnySourceActive() {
  let probe1 = StubProbe()
  let probe2 = StubProbe()
  probe1.active = false
  probe2.active = true
  let controller = SuppressionController(sources: [
    SuppressionController.Source(probe: probe1, isEnabled: { true }),
    SuppressionController.Source(probe: probe2, isEnabled: { true }),
  ])

  controller.reevaluate()

  #expect(controller.isSuppressed)
}

@MainActor
@Test func notSuppressedWhenAllSourcesDisabled() {
  let probe1 = StubProbe()
  let probe2 = StubProbe()
  probe1.active = true
  probe2.active = true
  let controller = SuppressionController(sources: [
    SuppressionController.Source(probe: probe1, isEnabled: { false }),
    SuppressionController.Source(probe: probe2, isEnabled: { false }),
  ])

  controller.reevaluate()

  #expect(!controller.isSuppressed)
}
