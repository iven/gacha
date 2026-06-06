import ArgumentParser
import Foundation

extension Card {
  struct Create: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "create",
      abstract: CLILocalized("card.create.abstract")
    )

    @Option(name: .long, help: ArgumentHelp(CLILocalized("card.create.option.body")))
    var body: String?

    @Option(name: .long, help: ArgumentHelp(CLILocalized("card.create.option.category")))
    var category: String?

    @Flag(name: .long, help: ArgumentHelp(CLILocalized("card.create.flag.json")))
    var json = false

    @Option(name: .long, help: ArgumentHelp(CLILocalized("card.create.option.port")))
    var port = 7771

    mutating func run() async throws {
      let bodyText = try readBody(body)
      var arguments: [String: Any] = ["body": bodyText]
      if let category { arguments["category"] = category }

      let text = try await callMCPTool(port: port, name: "create_card", arguments: arguments)

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
