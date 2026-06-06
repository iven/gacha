import ArgumentParser
import Darwin
import Foundation

func callMCPTool(
  port: Int,
  name: String,
  arguments: [String: Any] = [:]
) async throws -> String {
  let client = MCPClient(port: port)
  do {
    return try await client.callTool(name: name, arguments: arguments)
  } catch {
    fputs("\(error.localizedDescription)\n", stderr)
    throw ExitCode.failure
  }
}

func decodeCLIJSON<T: Decodable>(_ type: T.Type, from text: String) throws -> T {
  do {
    return try JSONDecoder.cli.decode(type, from: Data(text.utf8))
  } catch {
    fputs("\(CLILocalized("cli.error.parseResponse")): \(error.localizedDescription)\n", stderr)
    throw ExitCode.failure
  }
}

func decodeCLIJSONIfPresent<T: Decodable>(_ type: T.Type, from text: String) -> T? {
  try? JSONDecoder.cli.decode(type, from: Data(text.utf8))
}

func printJSON(_ object: [String: Any]) throws {
  let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
  print(String(data: data, encoding: .utf8) ?? "{}")
}

extension JSONDecoder {
  static var cli: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}
