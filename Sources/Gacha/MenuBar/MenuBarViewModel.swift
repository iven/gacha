import Combine
import Foundation

@MainActor
final class MenuBarViewModel: ObservableObject {
  @Published var isPaused = false

  var onTogglePause: ((Bool) -> Void)?
}
