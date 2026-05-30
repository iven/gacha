import SwiftUI

struct WindowOpenActionRegistrar: View {
  let registry: WindowOpenActionRegistry
  @Environment(\.openWindow) private var openWindow
  @Environment(\.openSettings) private var openSettings

  var body: some View {
    Color.clear
      .frame(width: 0, height: 0)
      .onAppear(perform: registerOpeners)
  }

  private func registerOpeners() {
    registry.register(.cards) {
      openWindow(id: GachaApp.cardWindowID)
    }
    registry.register(.settings) {
      openSettings()
    }
  }
}
