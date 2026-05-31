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
      let client = MCPClient(port: port)

      // Fetch category for this card ID
      let listText: String
      do {
        listText = try await client.callTool(name: "list_cards", arguments: [:])
      } catch {
        fputs("\(error.localizedDescription)\n", stderr)
        throw ExitCode.failure
      }

      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      guard let cards = try? decoder.decode([CardDTO].self, from: Data(listText.utf8)) else {
        fputs("\(CLILocalized("cli.error.parseResponse"))\n", stderr)
        throw ExitCode.failure
      }
      guard let card = cards.first(where: { $0.id == id }) else {
        fputs("\(String(format: CLILocalized("cli.error.cardNotFound"), id))\n", stderr)
        throw ExitCode.failure
      }

      do {
        _ = try await client.callTool(
          name: "delete_card",
          arguments: ["id": id, "category": card.category])
      } catch {
        fputs("\(error.localizedDescription)\n", stderr)
        throw ExitCode.failure
      }
    }
  }
}
