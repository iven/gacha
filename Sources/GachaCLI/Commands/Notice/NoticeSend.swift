import ArgumentParser
import Foundation

extension Notice {
  struct Send: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "send",
      abstract: CLILocalized("notice.send.abstract")
    )

    @Option(name: .long, help: ArgumentHelp(CLILocalized("notice.send.option.body")))
    var body: String?

    @Flag(name: .long, help: ArgumentHelp(CLILocalized("notice.send.flag.json")))
    var json = false

    @Option(name: .long, help: ArgumentHelp(CLILocalized("notice.send.option.port")))
    var port = 7771

    mutating func run() async throws {
      let markdown = try readBody(body, missingInputKey: "notice.send.error.tty")
      let text = try await callMCPTool(
        port: port,
        name: "send_notice",
        arguments: ["markdown": markdown])

      if json {
        print(text)
      }
    }
  }
}
