import Foundation
import MCP
import NIOCore
import NIOHTTP1
import NIOPosix

// MARK: - GachaMCPServer

final class GachaMCPServer: Sendable {
  private let repository: MemoryCardRepository
  private let noticeQueue: NoticeQueue
  private let state = ServerState()

  /// Observable running state — updated on MainActor after start/stop.
  @MainActor
  private(set) var isRunning = false

  init(repository: MemoryCardRepository, noticeQueue: NoticeQueue) {
    self.repository = repository
    self.noticeQueue = noticeQueue
  }

  func start(port: Int) async throws {
    try await state.start(port: port, repository: repository, noticeQueue: noticeQueue)
    await MainActor.run { isRunning = true }
  }

  func stop() async {
    await state.stop()
    await MainActor.run { isRunning = false }
  }

  func restart(port: Int) async throws {
    await MainActor.run { isRunning = false }
    await state.stop()
    try await state.start(port: port, repository: repository, noticeQueue: noticeQueue)
    await MainActor.run { isRunning = true }
  }
}

// MARK: - ServerState

private actor ServerState {
  private var channel: (any Channel)?
  private var sessions: [String: SessionContext] = [:]

  struct SessionContext {
    let server: Server
    let transport: StatefulHTTPServerTransport
  }

  func start(
    port: Int,
    repository: MemoryCardRepository,
    noticeQueue: NoticeQueue
  ) async throws {
    let group = MultiThreadedEventLoopGroup.singleton
    let bootstrap = ServerBootstrap(group: group)
      .serverChannelOption(.backlog, value: 256)
      .serverChannelOption(.socketOption(.so_reuseaddr), value: 1)
      .childChannelInitializer { [self] channel in
        channel.pipeline.configureHTTPServerPipeline().flatMap {
          let handler = HTTPHandler(
            state: self,
            repository: repository,
            noticeQueue: noticeQueue)
          return channel.pipeline.addHandler(handler)
        }
      }
      .childChannelOption(.socketOption(.so_reuseaddr), value: 1)
      .childChannelOption(.maxMessagesPerRead, value: 1)

    let channel = try await bootstrap.bind(host: "127.0.0.1", port: port).get()
    self.channel = channel
    AppLogger.app.info("MCP server started on port \(port)")
  }

  func stop() async {
    for (_, ctx) in sessions {
      await ctx.transport.disconnect()
    }
    sessions.removeAll()
    try? await channel?.close()
    channel = nil
    AppLogger.app.info("MCP server stopped")
  }

  func handleHTTPRequest(
    _ request: HTTPRequest,
    repository: MemoryCardRepository,
    noticeQueue: NoticeQueue
  ) async -> HTTPResponse {
    let sessionID = request.header(HTTPHeaderName.sessionID)

    // Route to existing session
    if let sessionID, let ctx = sessions[sessionID] {
      let response = await ctx.transport.handleRequest(request)
      if request.method.uppercased() == "DELETE" && response.statusCode == 200 {
        await ctx.transport.disconnect()
        sessions.removeValue(forKey: sessionID)
      }
      return response
    }

    // New initialize request → create session
    if request.method.uppercased() == "POST",
      let body = request.body,
      isInitializeRequest(body)
    {
      return await createSessionAndHandle(
        request,
        repository: repository,
        noticeQueue: noticeQueue)
    }

    if sessionID != nil {
      return .error(statusCode: 404, .invalidRequest("Session not found"))
    }
    return .error(statusCode: 400, .invalidRequest("Missing \(HTTPHeaderName.sessionID) header"))
  }

  private func createSessionAndHandle(
    _ request: HTTPRequest,
    repository: MemoryCardRepository,
    noticeQueue: NoticeQueue
  ) async -> HTTPResponse {
    let sessionID = UUID().uuidString

    struct FixedID: SessionIDGenerator {
      let id: String
      func generateSessionID() -> String { id }
    }

    let transport = StatefulHTTPServerTransport(
      sessionIDGenerator: FixedID(id: sessionID)
    )

    do {
      let server = await makeServer(repository: repository, noticeQueue: noticeQueue)
      try await server.start(transport: transport)
      sessions[sessionID] = SessionContext(server: server, transport: transport)

      let response = await transport.handleRequest(request)
      if case .error = response {
        sessions.removeValue(forKey: sessionID)
        await transport.disconnect()
      }
      return response
    } catch {
      await transport.disconnect()
      return .error(
        statusCode: 500,
        .internalError("Failed to create session: \(error.localizedDescription)"))
    }
  }
}

// MARK: - Server factory

private func makeServer(repository: MemoryCardRepository, noticeQueue: NoticeQueue) async -> Server
{
  let server = Server(
    name: "Gacha",
    version: "1.0.0",
    capabilities: .init(tools: .init(listChanged: false))
  )
  let registry = MCPToolRegistry(providers: [
    MemoryCardMCPToolProvider(repository: repository),
    NoticeMCPToolProvider(noticeQueue: noticeQueue),
  ])
  await registry.register(on: server)
  return server
}

// MARK: - Helpers

private func isInitializeRequest(_ data: Data) -> Bool {
  guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
    let method = json["method"] as? String
  else { return false }
  return method == "initialize"
}

// MARK: - NIO HTTP Handler

private final class HTTPHandler: ChannelInboundHandler, @unchecked Sendable {
  typealias InboundIn = HTTPServerRequestPart
  typealias OutboundOut = HTTPServerResponsePart

  private let state: ServerState
  private let repository: MemoryCardRepository
  private let noticeQueue: NoticeQueue

  private var head: HTTPRequestHead?
  private var bodyBuffer: ByteBuffer?

  init(state: ServerState, repository: MemoryCardRepository, noticeQueue: NoticeQueue) {
    self.state = state
    self.repository = repository
    self.noticeQueue = noticeQueue
  }

  func channelRead(context: ChannelHandlerContext, data: NIOAny) {
    switch unwrapInboundIn(data) {
    case .head(let requestHead):
      head = requestHead
      bodyBuffer = context.channel.allocator.buffer(capacity: 0)
    case .body(var buf):
      bodyBuffer?.writeBuffer(&buf)
    case .end:
      guard let head else { return }
      let bodyBuffer = self.bodyBuffer
      self.head = nil
      self.bodyBuffer = nil

      nonisolated(unsafe) let ctx = context
      Task {
        await self.handle(
          head: head,
          bodyBuffer: bodyBuffer,
          context: ctx,
          repository: repository,
          noticeQueue: noticeQueue)
      }
    }
  }

  private func handle(
    head: HTTPRequestHead,
    bodyBuffer: ByteBuffer?,
    context: ChannelHandlerContext,
    repository: MemoryCardRepository,
    noticeQueue: NoticeQueue
  ) async {
    let request = makeRequest(head: head, bodyBuffer: bodyBuffer)
    let response = await state.handleHTTPRequest(
      request,
      repository: repository,
      noticeQueue: noticeQueue)
    await write(response: response, version: head.version, context: context)
  }

  private func makeRequest(head: HTTPRequestHead, bodyBuffer: ByteBuffer?) -> HTTPRequest {
    var headers: [String: String] = [:]
    for (name, value) in head.headers {
      if let existing = headers[name] {
        headers[name] = existing + ", " + value
      } else {
        headers[name] = value
      }
    }

    let body: Data?
    if let buf = bodyBuffer, buf.readableBytes > 0,
      let bytes = buf.getBytes(at: 0, length: buf.readableBytes)
    {
      body = Data(bytes)
    } else {
      body = nil
    }

    let path = String(head.uri.split(separator: "?").first ?? Substring(head.uri))
    return HTTPRequest(method: head.method.rawValue, headers: headers, body: body, path: path)
  }

  private func write(
    response: HTTPResponse,
    version: HTTPVersion,
    context: ChannelHandlerContext
  ) async {
    nonisolated(unsafe) let ctx = context
    let eventLoop = ctx.eventLoop

    switch response {
    case .stream(let stream, let headers):
      eventLoop.execute {
        var responseHead = HTTPResponseHead(
          version: version,
          status: HTTPResponseStatus(statusCode: response.statusCode)
        )
        for (name, value) in headers { responseHead.headers.add(name: name, value: value) }
        ctx.writeAndFlush(self.wrapOutboundOut(.head(responseHead)), promise: nil)
      }

      do {
        for try await chunk in stream {
          eventLoop.execute {
            var buf = ctx.channel.allocator.buffer(capacity: chunk.count)
            buf.writeBytes(chunk)
            ctx.writeAndFlush(self.wrapOutboundOut(.body(.byteBuffer(buf))), promise: nil)
          }
        }
      } catch {}

      eventLoop.execute {
        ctx.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
      }

    default:
      let bodyData = response.bodyData
      eventLoop.execute {
        var responseHead = HTTPResponseHead(
          version: version,
          status: HTTPResponseStatus(statusCode: response.statusCode)
        )
        for (name, value) in response.headers { responseHead.headers.add(name: name, value: value) }
        ctx.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        if let data = bodyData {
          var buf = ctx.channel.allocator.buffer(capacity: data.count)
          buf.writeBytes(data)
          ctx.write(self.wrapOutboundOut(.body(.byteBuffer(buf))), promise: nil)
        }
        ctx.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
      }
    }
  }
}
