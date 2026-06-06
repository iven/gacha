import Foundation
import MCP
import Testing

@testable import Gacha

@MainActor
@Test func enqueueNoticeToolAppendsMarkdownToNoticeQueue() async throws {
  let createdAt = Date(timeIntervalSince1970: 1_800_000_000)
  let queue = NoticeQueue(now: { createdAt })
  let provider = NoticeMCPToolProvider(noticeQueue: queue)

  let result = try await provider.call(
    CallTool.Parameters(
      name: "enqueue_notice",
      arguments: ["markdown": .string("## Build finished")]))

  #expect(
    queue.pending == [
      NoticeMessage(markdown: "## Build finished", createdAt: createdAt)
    ])
  #expect(result?.isError == false)

  let response = try #require(result?.textContent)
  let decoded = try JSONDecoder.iso8601.decode(
    NoticeMessageResponse.self, from: Data(response.utf8))
  #expect(decoded.markdown == "## Build finished")
  #expect(decoded.createdAt == createdAt)
}

@MainActor
@Test func enqueueNoticeToolReportsMissingMarkdown() async throws {
  let queue = NoticeQueue()
  let provider = NoticeMCPToolProvider(noticeQueue: queue)

  let result = try await provider.call(CallTool.Parameters(name: "enqueue_notice"))

  #expect(queue.pending.isEmpty)
  #expect(result?.isError == true)
  #expect(result?.textContent == MCPStrings.missingMarkdown)
}

@MainActor
@Test func enqueueNoticeToolReportsBlankMarkdown() async throws {
  let queue = NoticeQueue()
  let provider = NoticeMCPToolProvider(noticeQueue: queue)

  let result = try await provider.call(
    CallTool.Parameters(name: "enqueue_notice", arguments: ["markdown": .string(" \n\t ")]))

  #expect(queue.pending.isEmpty)
  #expect(result?.isError == true)
  #expect(result?.textContent == MCPStrings.blankMarkdown)
}

@MainActor
@Test func noticeToolProviderIgnoresUnknownTools() async throws {
  let queue = NoticeQueue()
  let provider = NoticeMCPToolProvider(noticeQueue: queue)

  let result = try await provider.call(CallTool.Parameters(name: "list_cards"))

  #expect(result == nil)
}

private struct NoticeMessageResponse: Decodable {
  let markdown: String
  let createdAt: Date
}

extension CallTool.Result {
  fileprivate var textContent: String? {
    guard case .text(let text, _, _) = content.first else {
      return nil
    }
    return text
  }
}

extension JSONDecoder {
  fileprivate static var iso8601: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }
}
