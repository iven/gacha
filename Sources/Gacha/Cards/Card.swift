import Foundation

enum CardKind: String, Equatable {
  case memory
  case placeholder
  case notice
}

protocol Card {
  var kind: CardKind { get }
}
