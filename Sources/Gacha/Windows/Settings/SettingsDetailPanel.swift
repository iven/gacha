import SwiftUI

/// The right-hand panel: one continuous scroll view that stacks every settings
/// section. The sidebar drives it by writing `scrollTarget` (click -> scroll),
/// and scroll-spy drives the sidebar by writing `activeSection` (scroll ->
/// highlight).
struct SettingsDetailPanel: View {
  let directories: AppDirectories
  let launchAtLoginController: LaunchAtLoginController
  let settingsStore: SettingsStore
  let suppressionController: SuppressionController
  @ObservedObject var environment: AppEnvironment
  @ObservedObject var storageRelocationCoordinator: StorageRelocationCoordinator

  @Binding var activeSection: SettingsSection
  @Binding var scrollTarget: SettingsSection?

  @State private var sectionFrames: [SettingsSection: CGRect] = [:]
  @State private var isUserScrolling = false

  private let contentCoordinateSpace = "settingsContent"
  private let formTopInset: CGFloat = -15
  private let topThreshold: CGFloat = 16

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(spacing: 0) {
          ForEach(SettingsSection.allCases) { section in
            sectionBlock(for: section)
          }
        }
        .coordinateSpace(.named(contentCoordinateSpace))
      }
      .contentMargins(.top, formTopInset, for: .scrollContent)
      .onScrollGeometryChange(for: ScrollSnapshot.self) { geometry in
        ScrollSnapshot(
          visibleRect: geometry.visibleRect,
          contentHeight: geometry.contentSize.height)
      } action: { _, snapshot in
        if isUserScrolling {
          updateActiveSection(
            frames: sectionFrames,
            visibleRect: snapshot.visibleRect,
            contentHeight: snapshot.contentHeight)
        }
      }
      .onScrollPhaseChange { _, phase, context in
        isUserScrolling = phase.isUserDriven
        if isUserScrolling {
          updateActiveSection(
            frames: sectionFrames,
            visibleRect: context.geometry.visibleRect,
            contentHeight: context.geometry.contentSize.height)
        }
      }
      .onPreferenceChange(SectionFrameKey.self) { frames in
        sectionFrames = frames
      }
      .onChange(of: scrollTarget) { _, target in
        guard let target else { return }
        isUserScrolling = false
        activeSection = target
        withAnimation { proxy.scrollTo(target, anchor: .top) }
        scrollTarget = nil
      }
    }
  }

  private func sectionBlock(for section: SettingsSection) -> some View {
    Form {
      sectionView(for: section)
    }
    .formStyle(.grouped)
    .scrollDisabled(true)
    .frame(maxWidth: .infinity)
    .fixedSize(horizontal: false, vertical: true)
    .id(section)
    .background(frameReporter(for: section))
  }

  @ViewBuilder
  private func sectionView(for section: SettingsSection) -> some View {
    switch section {
    case .startup:
      StartupSection(
        launchAtLoginController: launchAtLoginController,
        settingsStore: settingsStore)
    case .notch:
      NotchSection(
        settingsStore: settingsStore,
        onIdleReminderTimeoutChanged: {
          environment.memoryNotchPresenter.refreshIdleReminderTimeout()
        })
    case .suppression:
      SuppressionSection(
        settingsStore: settingsStore,
        suppressionController: suppressionController)
    case .shortcuts:
      ShortcutsSection()
    case .mcp:
      MCPSettingsSection(environment: environment, settingsStore: settingsStore)
    case .cli:
      CLISettingsSection(environment: environment)
    case .storage:
      StorageSettingsSection(
        directories: directories,
        storageRelocationCoordinator: storageRelocationCoordinator)
    }
  }

  private func frameReporter(for section: SettingsSection) -> some View {
    GeometryReader { geometry in
      Color.clear.preference(
        key: SectionFrameKey.self,
        value: [section: geometry.frame(in: .named(contentCoordinateSpace))])
    }
  }

  private func updateActiveSection(
    frames: [SettingsSection: CGRect],
    visibleRect: CGRect,
    contentHeight: CGFloat
  ) {
    guard
      let visibleSection = anchoredSection(
        from: frames,
        visibleRect: visibleRect,
        contentHeight: contentHeight
      )
    else {
      return
    }
    if visibleSection != activeSection {
      activeSection = visibleSection
    }
  }

  private func anchoredSection(
    from frames: [SettingsSection: CGRect],
    visibleRect: CGRect,
    contentHeight: CGFloat
  ) -> SettingsSection? {
    guard !visibleRect.isEmpty else {
      return frames.min(by: { $0.value.minY < $1.value.minY })?.key
    }

    if contentHeight > 0, visibleRect.maxY >= contentHeight - 1 {
      return SettingsSection.allCases.last
    }

    let anchorY = visibleRect.minY + topThreshold
    return SettingsSection.allCases.last { section in
      guard let frame = frames[section] else { return false }
      return frame.minY <= anchorY
    } ?? SettingsSection.allCases.first
  }
}

private struct ScrollSnapshot: Equatable {
  var visibleRect: CGRect
  var contentHeight: CGFloat
}

private struct SectionFrameKey: PreferenceKey {
  static var defaultValue: [SettingsSection: CGRect] { [:] }
  static func reduce(
    value: inout [SettingsSection: CGRect],
    nextValue: () -> [SettingsSection: CGRect]
  ) {
    value.merge(nextValue()) { _, new in new }
  }
}

extension ScrollPhase {
  fileprivate var isUserDriven: Bool {
    switch self {
    case .tracking, .interacting, .decelerating:
      return true
    case .idle, .animating:
      return false
    }
  }
}
