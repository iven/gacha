import Foundation
import MCP

func mcpTextResult(_ text: String) -> CallTool.Result {
  .init(content: [.text(text: text, annotations: nil, _meta: nil)], isError: false)
}

func mcpTextResult(_ data: Data) -> CallTool.Result {
  let text = String(data: data, encoding: .utf8) ?? "[]"
  return .init(content: [.text(text: text, annotations: nil, _meta: nil)], isError: false)
}

func mcpErrorResult(_ message: String) -> CallTool.Result {
  .init(content: [.text(text: message, annotations: nil, _meta: nil)], isError: true)
}
