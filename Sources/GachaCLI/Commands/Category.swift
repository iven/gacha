import ArgumentParser

struct Category: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: CLILocalized("category.abstract"),
    subcommands: [List.self, Create.self, Rename.self, Delete.self]
  )
}
