import SwiftUI

enum NotchCueFill {
  case none
  case pulse(AnyShapeStyle)
  case ambient(AnyShapeStyle)
}

struct NotchAnimatedCue<Content: View>: View {
  let triggerID: Int
  let pulseCount: Int
  let isSuppressed: Bool
  let restingShell: Bool
  let showsShellWhileAnimating: Bool
  let fill: NotchCueFill
  let restingContentGlowAmount: Double
  /// Persists trigger progress outside the view when callers rebuild frequently.
  let externalHandledTriggerID: Binding<Int>?
  let content: (Double) -> Content

  @State private var localHandledTriggerID = Int.min
  @State private var isAnimating = false
  @State private var pulseAmount = 0.0
  @State private var animationTask: Task<Void, Never>?

  init(
    triggerID: Int,
    pulseCount: Int = 1,
    isSuppressed: Bool = false,
    restingShell: Bool = true,
    showsShellWhileAnimating: Bool = false,
    fill: NotchCueFill = .pulse(AnyShapeStyle(.red)),
    restingContentGlowAmount: Double = 0,
    externalHandledTriggerID: Binding<Int>? = nil,
    @ViewBuilder content: @escaping (Double) -> Content
  ) {
    self.triggerID = triggerID
    self.pulseCount = pulseCount
    self.isSuppressed = isSuppressed
    self.restingShell = restingShell
    self.showsShellWhileAnimating = showsShellWhileAnimating
    self.fill = fill
    self.restingContentGlowAmount = restingContentGlowAmount
    self.externalHandledTriggerID = externalHandledTriggerID
    self.content = content
  }

  var body: some View {
    ZStack {
      NotchToolbarStyle.background(restingShell: true)
        .opacity(visibleAnimationShellOpacity)

      fillLayer

      Capsule()
        .strokeBorder(.red, lineWidth: 1)
        .scaleEffect(1 + visiblePulseAmount * Metrics.strokeScaleDelta)
        .opacity(visiblePulseAmount * Metrics.redStrokeOpacity)

      content(visiblePulseAmount)
        .scaleEffect(1 + visiblePulseAmount * Metrics.contentScaleDelta)
        .shadow(
          color: .white.opacity(visibleContentGlowAmount * Metrics.contentShadowOpacity),
          radius: Metrics.contentShadowRadius)
    }
    .notchToolbarControl(restingShell: restingShell)
    .onAppear {
      handleTrigger(triggerID)
    }
    .onChange(of: triggerID) { _, triggerID in
      handleTrigger(triggerID)
    }
    .onDisappear {
      animationTask?.cancel()
    }
  }

  private var visiblePulseAmount: Double {
    isAnimating && !isSuppressed ? pulseAmount : 0
  }

  private var visibleContentGlowAmount: Double {
    guard !isSuppressed else {
      return 0
    }

    return max(restingContentGlowAmount, visiblePulseAmount)
  }

  @ViewBuilder private var fillLayer: some View {
    switch fill {
    case .none:
      EmptyView()
    case .pulse(let style):
      Capsule()
        .fill(style)
        .opacity(isSuppressed ? 0 : visiblePulseAmount * Metrics.redFillOpacity)
    case .ambient(let style):
      Group {
        NotchToolbarStyle.background(restingShell: true)
          .opacity(
            isAnimating && !isSuppressed ? (1 - visiblePulseAmount) * Metrics.redFillOpacity : 0)
        Capsule()
          .fill(style)
          .opacity(
            isSuppressed ? 0 : (isAnimating ? visiblePulseAmount : 1) * Metrics.redFillOpacity)
      }
    }
  }

  private var visibleAnimationShellOpacity: Double {
    showsShellWhileAnimating && !restingShell && isAnimating && !isSuppressed ? 1 : 0
  }

  private func handleTrigger(_ triggerID: Int) {
    if let externalHandledTriggerID {
      guard triggerID != externalHandledTriggerID.wrappedValue else {
        return
      }
      externalHandledTriggerID.wrappedValue = triggerID
    } else {
      guard triggerID != localHandledTriggerID else {
        return
      }
      localHandledTriggerID = triggerID
    }

    playAnimation()
  }

  private func playAnimation() {
    animationTask?.cancel()
    pulseAmount = 0
    withAnimation(.easeInOut(duration: Timing.shellFadeIn)) {
      isAnimating = true
    }

    animationTask = Task { @MainActor in
      for index in 0..<pulseCount {
        withAnimation(.easeInOut(duration: Timing.pulsePhase)) {
          pulseAmount = 1
        }
        do {
          try await Task.sleep(for: .seconds(Timing.pulsePhase))
        } catch {
          return
        }

        guard index < pulseCount - 1 else {
          break
        }

        withAnimation(.easeInOut(duration: Timing.pulsePhase)) {
          pulseAmount = 0
        }
        do {
          try await Task.sleep(for: .seconds(Timing.pulsePhase))
        } catch {
          return
        }
      }

      withAnimation(.easeInOut(duration: Timing.shellFadeOut)) {
        isAnimating = false
        pulseAmount = 0
      }
    }
  }
}

private enum Metrics {
  static let redFillOpacity = 0.3
  static let redStrokeOpacity = 0.3
  static let strokeScaleDelta = 0.05
  static let contentScaleDelta = 0.16
  static let contentShadowOpacity = 0.6
  static let contentShadowRadius: CGFloat = 3
}

private enum Timing {
  static let shellFadeIn = 0.18
  static let pulsePhase = 0.55
  static let shellFadeOut = 0.25
}
