import SwiftUI

@MainActor
final class NotchViewModel: ObservableObject {
  @Published var currentCard: any Card = EmptyStateCard()
  @Published var isPaused = false
  var onResumeRequested: (() -> Void)?
}
