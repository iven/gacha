import Foundation
import MCP

// MARK: - Tool registration

func registerMemoryCardTools(on server: Server, repository: MemoryCardRepository) async {
  await server.withMethodHandler(ListTools.self) { _ in
    .init(tools: memoryCardTools)
  }

  await server.withMethodHandler(CallTool.self) { params in
    try await handleMemoryCardTool(params, repository: repository)
  }
}

// MARK: - Tool definitions

private let memoryCardTools: [Tool] = [
  Tool(
    name: "list_memory_cards",
    description: "List memory cards, optionally filtered by directory.",
    inputSchema: .object([
      "type": .string("object"),
      "properties": .object([
        "directory": .object([
          "type": .string("string"),
          "description": .string("Directory name to filter by. Omit to list all cards."),
        ])
      ]),
    ])
  ),
  Tool(
    name: "create_memory_card",
    description: "Create a new memory card.",
    inputSchema: .object([
      "type": .string("object"),
      "properties": .object([
        "body": .object([
          "type": .string("string"),
          "description": .string("Markdown content of the card."),
        ]),
        "directory": .object([
          "type": .string("string"),
          "description": .string(
            "Directory to create the card in. Defaults to \"\(AppMetadata.defaultCategoryDirectoryName)\"."
          ),
        ]),
      ]),
      "required": .array([.string("body")]),
    ])
  ),
  Tool(
    name: "update_memory_card",
    description: "Update an existing memory card's content and/or directory.",
    inputSchema: .object([
      "type": .string("object"),
      "properties": .object([
        "id": .object([
          "type": .string("string"),
          "description": .string("Card ID."),
        ]),
        "body": .object([
          "type": .string("string"),
          "description": .string("New markdown content."),
        ]),
        "directory": .object([
          "type": .string("string"),
          "description": .string("New directory name (moves the card if changed)."),
        ]),
      ]),
      "required": .array([.string("id"), .string("body"), .string("directory")]),
    ])
  ),
  Tool(
    name: "delete_memory_card",
    description: "Delete a memory card.",
    inputSchema: .object([
      "type": .string("object"),
      "properties": .object([
        "id": .object([
          "type": .string("string"),
          "description": .string("Card ID."),
        ]),
        "directory": .object([
          "type": .string("string"),
          "description": .string("Directory the card currently belongs to."),
        ]),
      ]),
      "required": .array([.string("id"), .string("directory")]),
    ])
  ),
  Tool(
    name: "count_memory_cards",
    description: "Return the total number of memory cards.",
    inputSchema: .object([
      "type": .string("object"),
      "properties": .object([:]),
    ])
  ),
  Tool(
    name: "list_directories",
    description: "List all memory card directories.",
    inputSchema: .object([
      "type": .string("object"),
      "properties": .object([:]),
    ])
  ),
  Tool(
    name: "create_directory",
    description: "Create a new memory card directory.",
    inputSchema: .object([
      "type": .string("object"),
      "properties": .object([
        "name": .object([
          "type": .string("string"),
          "description": .string("Directory name."),
        ])
      ]),
      "required": .array([.string("name")]),
    ])
  ),
  Tool(
    name: "rename_directory",
    description: "Rename an existing memory card directory.",
    inputSchema: .object([
      "type": .string("object"),
      "properties": .object([
        "from": .object([
          "type": .string("string"),
          "description": .string("Current directory name."),
        ]),
        "to": .object([
          "type": .string("string"),
          "description": .string("New directory name."),
        ]),
      ]),
      "required": .array([.string("from"), .string("to")]),
    ])
  ),
  Tool(
    name: "delete_directory",
    description: "Delete a memory card directory and all cards inside it.",
    inputSchema: .object([
      "type": .string("object"),
      "properties": .object([
        "name": .object([
          "type": .string("string"),
          "description": .string("Directory name."),
        ])
      ]),
      "required": .array([.string("name")]),
    ])
  ),
]

// MARK: - Handlers

private func handleMemoryCardTool(
  _ params: CallTool.Parameters,
  repository: MemoryCardRepository
) async throws -> CallTool.Result {
  let encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .iso8601

  switch params.name {

  case "list_memory_cards":
    let directory = params.arguments?["directory"]?.stringValue
    let cards = try await MainActor.run { try repository.list(directory: directory) }
    return textResult(try encoder.encode(cards.map(MemoryCardDTO.init)))

  case "create_memory_card":
    guard let body = params.arguments?["body"]?.stringValue else {
      return errorResult("Missing required argument: body")
    }
    let directory =
      params.arguments?["directory"]?.stringValue ?? AppMetadata.defaultCategoryDirectoryName
    let card = try await MainActor.run { try repository.create(body: body, directory: directory) }
    return textResult(try encoder.encode(MemoryCardDTO(card)))

  case "update_memory_card":
    guard let id = params.arguments?["id"]?.stringValue,
      let body = params.arguments?["body"]?.stringValue,
      let directory = params.arguments?["directory"]?.stringValue
    else {
      return errorResult("Missing required arguments: id, body, directory")
    }
    let existing = try await MainActor.run {
      guard let card = try repository.list().first(where: { $0.id == id }) else {
        throw MemoryCardMCPError.notFound(id)
      }
      return card
    }
    var updated = existing
    updated.body = body
    updated.directory = directory
    try await MainActor.run { try repository.write(updated) }
    return textResult(try encoder.encode(MemoryCardDTO(updated)))

  case "delete_memory_card":
    guard let id = params.arguments?["id"]?.stringValue,
      let directory = params.arguments?["directory"]?.stringValue
    else {
      return errorResult("Missing required arguments: id, directory")
    }
    try await MainActor.run { try repository.delete(id: id, directory: directory) }
    return .init(content: [.text(text: "Deleted.", annotations: nil, _meta: nil)], isError: false)

  case "count_memory_cards":
    let count = try await MainActor.run { try repository.count() }
    return .init(
      content: [.text(text: "\(count)", annotations: nil, _meta: nil)], isError: false)

  case "list_directories":
    let dirs = try await MainActor.run { try repository.listDirectories() }
    return textResult(try JSONEncoder().encode(dirs))

  case "create_directory":
    guard let name = params.arguments?["name"]?.stringValue else {
      return errorResult("Missing required argument: name")
    }
    try await MainActor.run { try repository.createDirectory(name: name) }
    return .init(
      content: [.text(text: "Created.", annotations: nil, _meta: nil)], isError: false)

  case "rename_directory":
    guard let from = params.arguments?["from"]?.stringValue,
      let to = params.arguments?["to"]?.stringValue
    else {
      return errorResult("Missing required arguments: from, to")
    }
    try await MainActor.run { try repository.renameDirectory(from: from, to: to) }
    return .init(
      content: [.text(text: "Renamed.", annotations: nil, _meta: nil)], isError: false)

  case "delete_directory":
    guard let name = params.arguments?["name"]?.stringValue else {
      return errorResult("Missing required argument: name")
    }
    try await MainActor.run { try repository.deleteDirectory(name: name) }
    return .init(
      content: [.text(text: "Deleted.", annotations: nil, _meta: nil)], isError: false)

  default:
    return errorResult("Unknown tool: \(params.name)")
  }
}

// MARK: - Helpers

private func textResult(_ data: Data) -> CallTool.Result {
  let text = String(data: data, encoding: .utf8) ?? "[]"
  return .init(content: [.text(text: text, annotations: nil, _meta: nil)], isError: false)
}

private func errorResult(_ message: String) -> CallTool.Result {
  .init(content: [.text(text: message, annotations: nil, _meta: nil)], isError: true)
}

// MARK: - Errors

private enum MemoryCardMCPError: Error {
  case notFound(String)
}
