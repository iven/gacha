import Foundation

// MARK: - CardFormatter

enum CardFormatter {
  static func printList(_ cards: [CardDTO]) {
    guard !cards.isEmpty else { return }

    let headerID = CLILocalized("card.list.header.id")
    let headerCategory = CLILocalized("card.list.header.category")
    let headerPreview = CLILocalized("card.list.header.preview")

    let idWidth = max(headerID.count, 8)
    let categoryWidth = max(headerCategory.count, cards.map(\.category.count).max() ?? 0)

    let terminalWidth = terminalColumns()
    let previewWidth = max(
      headerPreview.count,
      terminalWidth - idWidth - categoryWidth - 4  // 4 = 2 separators × 2 spaces
    )

    func pad(_ str: String, _ width: Int) -> String {
      str + String(repeating: " ", count: max(0, width - str.count))
    }

    func truncate(_ str: String, _ width: Int) -> String {
      guard str.count > width else { return str }
      return String(str.prefix(width - 1)) + "…"
    }

    // Header
    let header =
      pad(headerID, idWidth)
      + "  "
      + pad(headerCategory, categoryWidth)
      + "  "
      + headerPreview
    print(header)

    // Rows
    for card in cards {
      let preview =
        card.body
        .components(separatedBy: .newlines)
        .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })
        ?? ""
      let row =
        pad(String(card.id.prefix(idWidth)), idWidth)
        + "  "
        + pad(truncate(card.category, categoryWidth), categoryWidth)
        + "  "
        + truncate(preview, previewWidth)
      print(row)
    }
  }

  // MARK: - Private

  private static func terminalColumns() -> Int {
    var windowSize = winsize()
    if ioctl(STDOUT_FILENO, TIOCGWINSZ, &windowSize) == 0, windowSize.ws_col > 0 {
      return Int(windowSize.ws_col)
    }
    return 80
  }
}
