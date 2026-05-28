import Foundation

enum StorageRelocationError: Error, LocalizedError, Equatable {
  case targetIsCurrentLocation
  case targetIsOccupied
  case targetMissingMarker
  case targetUnreadable(String)

  var errorDescription: String? {
    switch self {
    case .targetIsCurrentLocation:
      return AppStrings.localized("storage.relocate.error.sameLocation")
    case .targetIsOccupied:
      return AppStrings.localized("storage.relocate.error.occupied")
    case .targetMissingMarker:
      return AppStrings.localized("storage.relocate.error.missingMarker")
    case .targetUnreadable(let message):
      return message
    }
  }
}
