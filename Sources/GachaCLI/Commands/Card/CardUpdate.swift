import ArgumentParser
import Foundation

extension Card {
  struct Update: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "update",
      abstract: CLILocalized("card.update.abstract")
    )

    @Argument(help: ArgumentHelp(CLILocalized("card.update.arg.id")))
    var id: String

    @Option(name: .long, help: ArgumentHelp(CLILocalized("card.update.option.body")))
    var body: String?

    @Option(name: .long, help: ArgumentHelp(CLILocalized("card.update.option.category")))
    var category: String

    @Flag(name: .long, help: ArgumentHelp(CLILocalized("card.update.flag.json")))
    var json = false

    @Option(name: .long, help: ArgumentHelp(CLILocalized("card.update.option.port")))
    var port = 7771

    mutating func run() async throws {
      let bodyText = try readBody(body)
      let arguments: [String: Any] = ["id": id, "body": bodyText, "category": category]

      let text = try await callMCPTool(port: port, name: "update_card", arguments: arguments)

      if json {
        print(text)
        return
      }

      if let card = decodeCLIJSONIfPresent(CardDTO.self, from: text) {
        CardFormatter.printCard(card)
      }
    }
  }
}
