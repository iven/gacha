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
      let client = MCPClient(port: port)
      var arguments: [String: Any] = [:]
      if let category {
        arguments["category"] = category
      }

      let text: String
      do {
        text = try await client.callTool(name: "list_cards", arguments: arguments)
      } catch {
        fputs("\(error.localizedDescription)\n", stderr)
        throw ExitCode.failure
      }

      if json {
        print(text)
        return
      }

      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      do {
        let cards = try decoder.decode([CardDTO].self, from: Data(text.utf8))
        CardFormatter.printList(cards)
      } catch {
        fputs("\(CLILocalized("cli.error.parseResponse")): \(error.localizedDescription)\n", stderr)
        throw ExitCode.failure
      }
    }
  }
}
