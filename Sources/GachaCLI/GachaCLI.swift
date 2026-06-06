import ArgumentParser

@main
@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
struct GachaCLI: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "gacha",
    abstract: CLILocalized("cli.abstract"),
    subcommands: [Card.self, Category.self, Notice.self]
  )
}
