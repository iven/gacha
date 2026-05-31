import ArgumentParser

struct Card: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: CLILocalized("card.abstract"),
    subcommands: [List.self]
  )
}
