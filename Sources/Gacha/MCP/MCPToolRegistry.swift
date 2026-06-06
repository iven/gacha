import Foundation
import MCP

struct MCPToolRegistry: Sendable {
  private let providers: [any MCPToolProvider]

  init(providers: [any MCPToolProvider]) {
    self.providers = providers
  }

  func register(on server: Server) async {
    await server.withMethodHandler(ListTools.self) { _ in
      .init(tools: tools)
    }

    await server.withMethodHandler(CallTool.self) { params in
      try await call(params)
    }
  }

  private var tools: [Tool] {
    providers.flatMap(\.tools)
  }

  private func call(_ params: CallTool.Parameters) async throws -> CallTool.Result {
    for provider in providers {
      if let result = try await provider.call(params) {
        return result
      }
    }

    return mcpErrorResult(MCPStrings.unknownTool(params.name))
  }
}
