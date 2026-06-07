import ArgumentParser

struct Notice: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: CLILocalized("notice.abstract"),
    subcommands: [Send.self]
  )
}
