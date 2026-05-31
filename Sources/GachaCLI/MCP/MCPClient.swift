import Foundation

// MARK: - CardDTO

struct CardDTO: Decodable {
  let id: String
  let body: String
  let category: String
  let due: Date?
  let createdAt: Date
  let updatedAt: Date
}

// MARK: - MCPClient

struct MCPClient {
  let port: Int

  private var baseURL: URL {
    URL(string: "http://127.0.0.1:\(port)/mcp")!
  }

  /// Initializes an MCP session and calls a tool, returning the text content.
  func callTool(name: String, arguments: [String: Any] = [:]) async throws -> String {
    let sessionID = try await initialize()
    return try await callTool(name: name, arguments: arguments, sessionID: sessionID)
  }

  // MARK: - Private

  private func initialize() async throws -> String {
    let body: [String: Any] = [
      "jsonrpc": "2.0",
      "id": 1,
      "method": "initialize",
      "params": [
        "protocolVersion": "2024-11-05",
        "capabilities": [:] as [String: Any],
        "clientInfo": ["name": "GachaCLI", "version": "1.0"],
      ] as [String: Any],
    ]

    var request = makeRequest()
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (_, response) = try await perform(request)

    guard let http = response as? HTTPURLResponse else {
      throw MCPError.unexpectedResponse
    }
    guard let sessionID = http.value(forHTTPHeaderField: "MCP-Session-Id") else {
      throw MCPError.missingSessionID
    }

    // Send initialized notification
    try await sendInitialized(sessionID: sessionID)

    return sessionID
  }

  private func sendInitialized(sessionID: String) async throws {
    let body: [String: Any] = [
      "jsonrpc": "2.0",
      "method": "notifications/initialized",
    ]

    var request = makeRequest(sessionID: sessionID)
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    _ = try await perform(request)
  }

  private func callTool(
    name: String,
    arguments: [String: Any],
    sessionID: String
  ) async throws -> String {
    let body: [String: Any] = [
      "jsonrpc": "2.0",
      "id": 2,
      "method": "tools/call",
      "params": [
        "name": name,
        "arguments": arguments,
      ] as [String: Any],
    ]

    var request = makeRequest(sessionID: sessionID)
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, _) = try await perform(request)

    let jsonData = try extractJSONFromSSE(data)

    guard
      let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
      let result = json["result"] as? [String: Any],
      let content = result["content"] as? [[String: Any]],
      let first = content.first,
      let text = first["text"] as? String
    else {
      throw MCPError.unexpectedResponse
    }

    if result["isError"] as? Bool == true {
      throw MCPError.serverError(text)
    }

    return text
  }

  // MARK: - Helpers

  private func makeRequest(sessionID: String? = nil) -> URLRequest {
    var request = URLRequest(url: baseURL)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json, text/event-stream", forHTTPHeaderField: "Accept")
    if let sessionID {
      request.setValue(sessionID, forHTTPHeaderField: "MCP-Session-Id")
    }
    return request
  }

  private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
    do {
      return try await URLSession.shared.data(for: request)
    } catch {
      throw MCPError.connectionFailed
    }
  }

  /// Extracts JSON data from an SSE response body.
  /// SSE format: lines like "data: {...json...}"
  private func extractJSONFromSSE(_ data: Data) throws -> Data {
    guard let text = String(data: data, encoding: .utf8) else {
      throw MCPError.unexpectedResponse
    }

    // Try direct JSON first (non-SSE response)
    if let firstByte = text.first, firstByte == "{" || firstByte == "[" {
      return data
    }

    // Parse SSE: find a non-empty line starting with "data: "
    for line in text.components(separatedBy: "\n") {
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      if trimmed.hasPrefix("data: ") {
        let json = String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespaces)
        if !json.isEmpty, let jsonData = json.data(using: .utf8) {
          return jsonData
        }
      }
    }

    throw MCPError.unexpectedResponse
  }
}

// MARK: - MCPError

enum MCPError: Error, LocalizedError {
  case connectionFailed
  case missingSessionID
  case unexpectedResponse
  case serverError(String)

  var errorDescription: String? {
    switch self {
    case .connectionFailed:
      return CLILocalized("cli.error.connectionFailed")
    case .missingSessionID:
      return CLILocalized("cli.error.missingSessionID")
    case .unexpectedResponse:
      return CLILocalized("cli.error.unexpectedResponse")
    case .serverError(let message):
      return message
    }
  }
}
