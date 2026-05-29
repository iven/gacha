import AppKit

extension NSMutableAttributedString {
  func append(string: String, attributes: [NSAttributedString.Key: Any] = [:]) {
    append(NSAttributedString(string: string, attributes: attributes))
  }
}
