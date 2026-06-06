import ArgumentParser
import Foundation

extension Notice {
  struct Enqueue: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
      commandName: "enqueue",
      abstract: CLILocalized("notice.enqueue.abstract")
    )

    @Option(name: .long, help: ArgumentHelp(CLILocalized("notice.enqueue.option.body")))
    var body: String?

    @Flag(name: .long, help: ArgumentHelp(CLILocalized("notice.enqueue.flag.json")))
    var json = false

    @Option(name: .long, help: ArgumentHelp(CLILocalized("notice.enqueue.option.port")))
    var port = 7771

    mutating func run() async throws {
      let markdown = try readBody(body, missingInputKey: "notice.enqueue.error.tty")
      let text = try await callMCPTool(
        port: port,
        name: "enqueue_notice",
        arguments: ["markdown": markdown])

      if json {
        print(text)
      }
    }
  }
}
