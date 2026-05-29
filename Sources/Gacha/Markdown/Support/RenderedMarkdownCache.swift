import AppKit

/// A small thread-safe LRU cache keyed by appearance + content hash.
final class RenderedMarkdownCache: @unchecked Sendable {
  private let limit: Int
  private let lock = NSLock()
  private var values: [String: NSAttributedString] = [:]
  private var accessOrder: [String] = []

  init(limit: Int) {
    self.limit = limit
  }

  func value(forKey key: String) -> NSAttributedString? {
    lock.lock()
    defer { lock.unlock() }
    guard let value = values[key] else {
      return nil
    }
    touch(key)
    return value
  }

  func insert(_ attributedString: NSAttributedString, forKey key: String) {
    lock.lock()
    defer { lock.unlock() }

    values[key] = attributedString
    touch(key)

    while values.count > limit, let oldestKey = accessOrder.first {
      accessOrder.removeFirst()
      values.removeValue(forKey: oldestKey)
    }
  }

  private func touch(_ key: String) {
    if let existing = accessOrder.firstIndex(of: key) {
      accessOrder.remove(at: existing)
    }
    accessOrder.append(key)
  }
}
