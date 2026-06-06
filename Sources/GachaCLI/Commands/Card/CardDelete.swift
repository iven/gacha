import ArgumentParser
import Foundation

extension Card {
  struct Delete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "delete",
      abstract: CLILocalized("card.delete.abstract")
    )

    @Argument(help: ArgumentHelp(CLILocalized("card.delete.arg.id")))
    var id: String

    @Option(name: .long, help: ArgumentHelp(CLILocalized("card.delete.option.port")))
    var port = 7771

    mutating func run() async throws {
      // Fetch category for this card ID
      let listText = try await callMCPTool(port: port, name: "list_cards")

      let cards = try decodeCLIJSON([CardDTO].self, from: listText)
      guard let card = cards.first(where: { $0.id == id }) else {
        fputs("\(String(format: CLILocalized("cli.error.cardNotFound"), id))\n", stderr)
        throw ExitCode.failure
      }

      _ = try await callMCPTool(
        port: port,
        name: "delete_card",
        arguments: ["id": id, "category": card.category])
    }
  }
}
