import ArgumentParser

struct Category: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: CLILocalized("category.abstract")
  )
}
