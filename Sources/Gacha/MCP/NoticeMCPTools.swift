import Foundation
import MCP

struct NoticeMCPToolProvider: MCPToolProvider {
  let noticeQueue: NoticeQueue

  var tools: [Tool] {
    [
      Tool(
        name: "enqueue_notice",
        description: MCPStrings.enqueueNoticeDescription,
        inputSchema: .object([
          "type": .string("object"),
          "properties": .object([
            "markdown": .object([
              "type": .string("string"),
              "description": .string(MCPStrings.enqueueNoticeMarkdownParam),
            ])
          ]),
          "required": .array([.string("markdown")]),
        ])
      )
    ]
  }

  func call(_ params: CallTool.Parameters) async throws -> CallTool.Result? {
    guard params.name == "enqueue_notice" else {
      return nil
    }

    guard let markdown = params.arguments?["markdown"]?.stringValue else {
      return mcpErrorResult(MCPStrings.missingMarkdown)
    }

    let message = await MainActor.run {
      noticeQueue.enqueue(markdown: markdown)
    }
    return mcpTextResult(try JSONEncoder.iso8601.encode(NoticeMessageDTO(message)))
  }
}
