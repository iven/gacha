import Foundation
import MCP

struct NoticeMCPToolProvider: MCPToolProvider {
  let noticeQueue: NoticeQueue

  var tools: [Tool] {
    [
      Tool(
        name: "send_notice",
        description: MCPStrings.sendNoticeDescription,
        inputSchema: .object([
          "type": .string("object"),
          "properties": .object([
            "markdown": .object([
              "type": .string("string"),
              "description": .string(MCPStrings.sendNoticeMarkdownParam),
            ])
          ]),
          "required": .array([.string("markdown")]),
        ])
      )
    ]
  }

  func call(_ params: CallTool.Parameters) async throws -> CallTool.Result? {
    guard params.name == "send_notice" else {
      return nil
    }

    guard let markdown = params.arguments?["markdown"]?.stringValue else {
      return mcpErrorResult(MCPStrings.missingMarkdown)
    }
    guard !markdown.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return mcpErrorResult(MCPStrings.blankMarkdown)
    }

    let message = await MainActor.run {
      noticeQueue.enqueue(markdown: markdown)
    }
    return mcpTextResult(try JSONEncoder.iso8601.encode(NoticeMessageDTO(message)))
  }
}
