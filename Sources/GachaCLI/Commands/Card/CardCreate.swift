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

      let client = MCPClient(port: port)
      let text: String
      do {
        text = try await client.callTool(name: "create_card", arguments: arguments)
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
      if let card = try? decoder.decode(CardDTO.self, from: Data(text.utf8)) {
        CardFormatter.printCard(card)
      }
    }
  }
}
