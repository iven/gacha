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

private var memoryCardTools: [Tool] {
  [
    Tool(
      name: "list_cards",
      description: MCPStrings.listCardsDescription,
      inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
          "category": .object([
            "type": .string("string"),
            "description": .string(MCPStrings.listCardsCategoryParam),
          ])
        ]),
      ])
    ),
    Tool(
      name: "create_card",
      description: MCPStrings.createCardDescription,
      inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
          "body": .object([
            "type": .string("string"),
            "description": .string(MCPStrings.createCardBodyParam),
          ]),
          "category": .object([
            "type": .string("string"),
            "description": .string(MCPStrings.createCardCategoryDefault()),
          ]),
        ]),
        "required": .array([.string("body")]),
      ])
    ),
    Tool(
      name: "update_card",
      description: MCPStrings.updateCardDescription,
      inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
          "id": .object([
            "type": .string("string"),
            "description": .string(MCPStrings.updateCardIDParam),
          ]),
          "body": .object([
            "type": .string("string"),
            "description": .string(MCPStrings.updateCardBodyParam),
          ]),
          "category": .object([
            "type": .string("string"),
            "description": .string(MCPStrings.updateCardCategoryParam),
          ]),
        ]),
        "required": .array([.string("id"), .string("body"), .string("category")]),
      ])
    ),
    Tool(
      name: "delete_card",
      description: MCPStrings.deleteCardDescription,
      inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
          "id": .object([
            "type": .string("string"),
            "description": .string(MCPStrings.updateCardIDParam),
          ]),
          "category": .object([
            "type": .string("string"),
            "description": .string(MCPStrings.deleteCardCategoryParam),
          ]),
        ]),
        "required": .array([.string("id"), .string("category")]),
      ])
    ),
    Tool(
      name: "count_cards",
      description: MCPStrings.countCardsDescription,
      inputSchema: .object([
        "type": .string("object"),
        "properties": .object([:]),
      ])
    ),
    Tool(
      name: "list_categories",
      description: MCPStrings.listCategoriesDescription,
      inputSchema: .object([
        "type": .string("object"),
        "properties": .object([:]),
      ])
    ),
    Tool(
      name: "create_category",
      description: MCPStrings.createCategoryDescription,
      inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
          "name": .object([
            "type": .string("string"),
            "description": .string(MCPStrings.createCategoryNameParam),
          ])
        ]),
        "required": .array([.string("name")]),
      ])
    ),
    Tool(
      name: "rename_category",
      description: MCPStrings.renameCategoryDescription,
      inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
          "from": .object([
            "type": .string("string"),
            "description": .string(MCPStrings.renameCategoryFromParam),
          ]),
          "to": .object([
            "type": .string("string"),
            "description": .string(MCPStrings.renameCategoryToParam),
          ]),
        ]),
        "required": .array([.string("from"), .string("to")]),
      ])
    ),
    Tool(
      name: "delete_category",
      description: MCPStrings.deleteCategoryDescription,
      inputSchema: .object([
        "type": .string("object"),
        "properties": .object([
          "name": .object([
            "type": .string("string"),
            "description": .string(MCPStrings.deleteCategoryNameParam),
          ])
        ]),
        "required": .array([.string("name")]),
      ])
    ),
  ]
}

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
      return errorResult(MCPStrings.missingBody)
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
      return errorResult(MCPStrings.missingIDBodyCategory)
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
      return errorResult(MCPStrings.missingIDCategory)
    }
    try await MainActor.run { try repository.delete(id: id, directory: category) }
    return textResult(MCPStrings.deleted)

  case "count_cards":
    let count = try await MainActor.run { try repository.count() }
    return .init(
      content: [.text(text: "\(count)", annotations: nil, _meta: nil)], isError: false)

  case "list_categories":
    let categories = try await MainActor.run { try repository.listDirectories() }
    return textResult(try JSONEncoder().encode(categories))

  case "create_category":
    guard let name = params.arguments?["name"]?.stringValue else {
      return errorResult(MCPStrings.missingName)
    }
    try await MainActor.run { try repository.createDirectory(name: name) }
    return textResult(MCPStrings.created)

  case "rename_category":
    guard let from = params.arguments?["from"]?.stringValue,
      let to = params.arguments?["to"]?.stringValue
    else {
      return errorResult(MCPStrings.missingFromTo)
    }
    try await MainActor.run { try repository.renameDirectory(from: from, to: to) }
    return textResult(MCPStrings.renamed)

  case "delete_category":
    guard let name = params.arguments?["name"]?.stringValue else {
      return errorResult(MCPStrings.missingName)
    }
    try await MainActor.run { try repository.deleteDirectory(name: name) }
    return textResult(MCPStrings.deleted)

  default:
    return errorResult(MCPStrings.unknownTool(params.name))
  }
}

// MARK: - Helpers

private func textResult(_ text: String) -> CallTool.Result {
  .init(content: [.text(text: text, annotations: nil, _meta: nil)], isError: false)
}

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
    case .notFound(let id): return MCPStrings.cardNotFound(id)
    }
  }
}

extension MemoryCardFileRepositoryError {
  var mcpMessage: String {
    switch self {
    case .invalidCategoryName(let name):
      return MCPStrings.invalidCategoryName(name)
    case .categoryAlreadyExists(let name):
      return MCPStrings.categoryAlreadyExists(name)
    case .categoryNotFound(let name):
      return MCPStrings.categoryNotFound(name)
    case .categoryNotRenamable(let name):
      return MCPStrings.categoryNotRenamable(name)
    case .categoryNotDeletable(let name):
      return MCPStrings.categoryNotDeletable(name)
    case .invalidCardID(let id):
      return MCPStrings.invalidCardID(id)
    case .missingFrontMatter(let url):
      return MCPStrings.missingFrontMatter(url.lastPathComponent)
    }
  }
}
