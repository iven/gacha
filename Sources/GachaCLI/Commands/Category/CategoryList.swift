import ArgumentParser
import Foundation

extension Category {
  struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "list",
      abstract: CLILocalized("category.list.abstract")
    )

    @Flag(name: .long, help: ArgumentHelp(CLILocalized("category.list.flag.json")))
    var json = false

    @Option(name: .long, help: ArgumentHelp(CLILocalized("category.list.option.port")))
    var port = 7771

    mutating func run() async throws {
      let client = MCPClient(port: port)
      let text: String
      do {
        text = try await client.callTool(name: "list_categories", arguments: [:])
      } catch {
        fputs("\(error.localizedDescription)\n", stderr)
        throw ExitCode.failure
      }

      if json {
        print(text)
        return
      }

      if let categories = try? JSONDecoder().decode([String].self, from: Data(text.utf8)) {
        categories.forEach { print($0) }
      }
    }
  }
}
