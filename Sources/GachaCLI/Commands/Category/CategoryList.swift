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
      let text = try await callMCPTool(port: port, name: "list_categories")

      if json {
        print(text)
        return
      }

      let categories = try decodeCLIJSON([String].self, from: text)
      categories.forEach { print($0) }
    }
  }
}
