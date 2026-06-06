import ArgumentParser
import Foundation

extension Card {
  struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "list",
      abstract: CLILocalized("card.list.abstract")
    )

    @Option(name: .long, help: ArgumentHelp(CLILocalized("card.list.option.category")))
    var category: String?

    @Flag(name: .long, help: ArgumentHelp(CLILocalized("card.list.flag.json")))
    var json = false

    @Option(name: .long, help: ArgumentHelp(CLILocalized("card.list.option.port")))
    var port = 7771

    mutating func run() async throws {
      var arguments: [String: Any] = [:]
      if let category {
        arguments["category"] = category
      }

      let text = try await callMCPTool(port: port, name: "list_cards", arguments: arguments)

      if json {
        print(text)
        return
      }

      let cards = try decodeCLIJSON([CardDTO].self, from: text)
      CardFormatter.printList(cards)
    }
  }
}
