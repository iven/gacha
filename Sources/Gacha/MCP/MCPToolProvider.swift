import MCP

protocol MCPToolProvider: Sendable {
  var tools: [Tool] { get }

  func call(_ params: CallTool.Parameters) async throws -> CallTool.Result?
}
