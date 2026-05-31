import ArgumentParser
import Darwin

extension Category {
  struct Delete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "delete",
      abstract: CLILocalized("category.delete.abstract")
    )

    @Argument(help: ArgumentHelp(CLILocalized("category.delete.arg.name")))
    var name: String

    @Option(name: .long, help: ArgumentHelp(CLILocalized("category.delete.option.port")))
    var port = 7771

    mutating func run() async throws {
      let client = MCPClient(port: port)
      do {
        _ = try await client.callTool(name: "delete_category", arguments: ["name": name])
      } catch {
        fputs("\(error.localizedDescription)\n", stderr)
        throw ExitCode.failure
      }
    }
  }
}
