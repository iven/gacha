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

      let client = MCPClient(port: port)
      let text: String
      do {
        text = try await client.callTool(name: "update_card", arguments: arguments)
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
