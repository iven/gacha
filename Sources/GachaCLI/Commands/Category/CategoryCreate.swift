import ArgumentParser
import Darwin

extension Category {
  struct Create: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "create",
      abstract: CLILocalized("category.create.abstract")
    )

    @Argument(help: ArgumentHelp(CLILocalized("category.create.arg.name")))
    var name: String

    @Option(name: .long, help: ArgumentHelp(CLILocalized("category.create.option.port")))
    var port = 7771

    mutating func run() async throws {
      _ = try await callMCPTool(port: port, name: "create_category", arguments: ["name": name])
    }
  }
}
