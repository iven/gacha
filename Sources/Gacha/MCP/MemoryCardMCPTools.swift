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
    name: "list_cards",
    description: "List cards, optionally filtered by category.",
    inputSchema: .object([
      "type": .string("object"),
      "properties": .object([
        "category": .object([
          "type": .string("string"),
          "description": .string("Category name to filter by. Omit to list all cards."),
        ])
      ]),
    ])
  ),
  Tool(
    name: "create_card",
    description: "Create a new card.",
    inputSchema: .object([
      "type": .string("object"),
      "properties": .object([
        "body": .object([
          "type": .string("string"),
          "description": .string("Markdown content of the card."),
        ]),
        "category": .object([
          "type": .string("string"),
          "description": .string(
            "Category to create the card in. Defaults to \"\(AppMetadata.defaultCategoryDirectoryName)\"."
          ),
        ]),
      ]),
      "required": .array([.string("body")]),
    ])
  ),
  Tool(
    name: "update_card",
    description: "Update an existing card's content and/or category.",
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
        "category": .object([
          "type": .string("string"),
          "description": .string("New category name (moves the card if changed)."),
        ]),
      ]),
      "required": .array([.string("id"), .string("body"), .string("category")]),
    ])
  ),
  Tool(
    name: "delete_card",
    description: "Delete a card.",
    inputSchema: .object([
      "type": .string("object"),
      "properties": .object([
        "id": .object([
          "type": .string("string"),
          "description": .string("Card ID."),
        ]),
        "category": .object([
          "type": .string("string"),
          "description": .string("Category the card currently belongs to."),
        ]),
      ]),
      "required": .array([.string("id"), .string("category")]),
    ])
  ),
  Tool(
    name: "count_cards",
    description: "Return the total number of cards.",
    inputSchema: .object([
      "type": .string("object"),
      "properties": .object([:]),
    ])
  ),
  Tool(
    name: "list_categories",
    description: "List all card categories.",
    inputSchema: .object([
      "type": .string("object"),
      "properties": .object([:]),
    ])
  ),
  Tool(
    name: "create_category",
    description: "Create a new card category.",
    inputSchema: .object([
      "type": .string("object"),
      "properties": .object([
        "name": .object([
          "type": .string("string"),
          "description": .string("Category name."),
        ])
      ]),
      "required": .array([.string("name")]),
    ])
  ),
  Tool(
    name: "rename_category",
    description: "Rename an existing card category.",
    inputSchema: .object([
      "type": .string("object"),
      "properties": .object([
        "from": .object([
          "type": .string("string"),
          "description": .string("Current category name."),
        ]),
        "to": .object([
          "type": .string("string"),
          "description": .string("New category name."),
        ]),
      ]),
      "required": .array([.string("from"), .string("to")]),
    ])
  ),
  Tool(
    name: "delete_category",
    description: "Delete a card category and all cards inside it.",
    inputSchema: .object([
      "type": .string("object"),
      "properties": .object([
        "name": .object([
          "type": .string("string"),
          "description": .string("Category name."),
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
  do {
    return try await handleMemoryCardToolInner(params, repository: repository)
  } catch let error as MemoryCardFileRepositoryError {
    return errorResult(error.mcpMessage)
  } catch let error as MemoryCardMCPError {
    return errorResult(error.mcpMessage)
  } catch {
    return errorResult(error.localizedDescription)
  }
}

private func handleMemoryCardToolInner(
  _ params: CallTool.Parameters,
  repository: MemoryCardRepository
) async throws -> CallTool.Result {
  let encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .iso8601

  switch params.name {

  case "list_cards":
    let category = params.arguments?["category"]?.stringValue
    let cards = try await MainActor.run { try repository.list(directory: category) }
    return textResult(try encoder.encode(cards.map(MemoryCardDTO.init)))

  case "create_card":
    guard let body = params.arguments?["body"]?.stringValue else {
      return errorResult("Missing required argument: body")
    }
    let category =
      params.arguments?["category"]?.stringValue ?? AppMetadata.defaultCategoryDirectoryName
    let card = try await MainActor.run { try repository.create(body: body, directory: category) }
    return textResult(try encoder.encode(MemoryCardDTO(card)))

  case "update_card":
    guard let id = params.arguments?["id"]?.stringValue,
      let body = params.arguments?["body"]?.stringValue,
      let category = params.arguments?["category"]?.stringValue
    else {
      return errorResult("Missing required arguments: id, body, category")
    }
    let existing = try await MainActor.run {
      guard let card = try repository.list().first(where: { $0.id == id }) else {
        throw MemoryCardMCPError.notFound(id)
      }
      return card
    }
    var updated = existing
    updated.body = body
    updated.directory = category
    try await MainActor.run { try repository.write(updated) }
    return textResult(try encoder.encode(MemoryCardDTO(updated)))

  case "delete_card":
    guard let id = params.arguments?["id"]?.stringValue,
      let category = params.arguments?["category"]?.stringValue
    else {
      return errorResult("Missing required arguments: id, category")
    }
    try await MainActor.run { try repository.delete(id: id, directory: category) }
    return .init(content: [.text(text: "Deleted.", annotations: nil, _meta: nil)], isError: false)

  case "count_cards":
    let count = try await MainActor.run { try repository.count() }
    return .init(
      content: [.text(text: "\(count)", annotations: nil, _meta: nil)], isError: false)

  case "list_categories":
    let categories = try await MainActor.run { try repository.listDirectories() }
    return textResult(try JSONEncoder().encode(categories))

  case "create_category":
    guard let name = params.arguments?["name"]?.stringValue else {
      return errorResult("Missing required argument: name")
    }
    try await MainActor.run { try repository.createDirectory(name: name) }
    return .init(
      content: [.text(text: "Created.", annotations: nil, _meta: nil)], isError: false)

  case "rename_category":
    guard let from = params.arguments?["from"]?.stringValue,
      let to = params.arguments?["to"]?.stringValue
    else {
      return errorResult("Missing required arguments: from, to")
    }
    try await MainActor.run { try repository.renameDirectory(from: from, to: to) }
    return .init(
      content: [.text(text: "Renamed.", annotations: nil, _meta: nil)], isError: false)

  case "delete_category":
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

  var mcpMessage: String {
    switch self {
    case .notFound(let id): return "Card not found: \(id)"
    }
  }
}

extension MemoryCardFileRepositoryError {
  var mcpMessage: String {
    switch self {
    case .invalidCategoryName(let name):
      return "Invalid category name: \"\(name)\""
    case .categoryAlreadyExists(let name):
      return "Category already exists: \"\(name)\""
    case .categoryNotFound(let name):
      return "Category not found: \"\(name)\""
    case .categoryNotRenamable(let name):
      return "Category cannot be renamed: \"\(name)\""
    case .categoryNotDeletable(let name):
      return "Category cannot be deleted: \"\(name)\""
    case .invalidCardID(let id):
      return "Invalid card ID: \"\(id)\""
    case .missingFrontMatter(let url):
      return "Missing front matter in card file: \(url.lastPathComponent)"
    }
  }
}
