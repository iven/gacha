import ArgumentParser
import Darwin

extension Category {
  struct Rename: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "rename",
      abstract: CLILocalized("category.rename.abstract")
    )

    @Argument(help: ArgumentHelp(CLILocalized("category.rename.arg.old")))
    var oldName: String

    @Argument(help: ArgumentHelp(CLILocalized("category.rename.arg.new")))
    var newName: String

    @Option(name: .long, help: ArgumentHelp(CLILocalized("category.rename.option.port")))
    var port = 7771

    mutating func run() async throws {
      let client = MCPClient(port: port)
      do {
        _ = try await client.callTool(
          name: "rename_category",
          arguments: ["from": oldName, "to": newName])
      } catch {
        fputs("\(error.localizedDescription)\n", stderr)
        throw ExitCode.failure
      }
    }
  }
}
