import Foundation
import GRDB

final class MemoryCardIndexStore {
  private let dbQueue: DatabaseQueue

  init(databaseURL: URL, fileManager: FileManager = .default) throws {
    try fileManager.createDirectory(
      at: databaseURL.deletingLastPathComponent(),
      withIntermediateDirectories: true)
    dbQueue = try DatabaseQueue(path: databaseURL.path)
    try migrate()
  }

  func upsert(_ card: MemoryCard, filePath: String) throws {
    try dbQueue.write { database in
      try database.execute(
        sql: """
          INSERT INTO memory_cards (
            id, display_title, body, file_path, directory,
            due, stability, difficulty, last_seen, created_at, updated_at
          )
          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            display_title = excluded.display_title,
            body = excluded.body,
            file_path = excluded.file_path,
            directory = excluded.directory,
            due = excluded.due,
            stability = excluded.stability,
            difficulty = excluded.difficulty,
            last_seen = excluded.last_seen,
            created_at = excluded.created_at,
            updated_at = excluded.updated_at
          """,
        arguments: [
          card.id,
          card.displayTitle,
          card.body,
          filePath,
          card.directory,
          card.due.map(formatDate),
          card.stability,
          card.difficulty,
          card.lastSeen.map(formatDate),
          formatDate(card.createdAt),
          formatDate(card.updatedAt),
        ])
    }
  }

  func delete(id: String) throws {
    try dbQueue.write { database in
      try database.execute(sql: "DELETE FROM memory_cards WHERE id = ?", arguments: [id])
    }
  }

  func find(id: String) throws -> MemoryCard? {
    try dbQueue.read { database in
      try Row.fetchOne(
        database,
        sql: "SELECT * FROM memory_cards WHERE id = ?",
        arguments: [id]
      ).map(memoryCard)
    }
  }

  func list(directory: String? = nil) throws -> [MemoryCard] {
    try dbQueue.read { database in
      let rows: [Row]
      if let directory {
        rows = try Row.fetchAll(
          database,
          sql: """
            SELECT * FROM memory_cards
            WHERE directory = ?
            ORDER BY updated_at DESC, id DESC
            """,
          arguments: [directory])
      } else {
        rows = try Row.fetchAll(
          database,
          sql: "SELECT * FROM memory_cards ORDER BY updated_at DESC, id DESC")
      }

      return rows.map(memoryCard)
    }
  }

  func count() throws -> Int {
    try dbQueue.read { database in
      try Int.fetchOne(database, sql: "SELECT COUNT(*) FROM memory_cards") ?? 0
    }
  }

  func rebuild(from repository: MemoryCardFileRepository) throws {
    let cards = try repository.list()
    try dbQueue.write { database in
      try database.execute(sql: "DELETE FROM memory_cards")
      for card in cards {
        try database.execute(
          sql: """
            INSERT INTO memory_cards (
              id, display_title, body, file_path, directory,
              due, stability, difficulty, last_seen, created_at, updated_at
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
          arguments: [
            card.id,
            card.displayTitle,
            card.body,
            card.relativeFilePath,
            card.directory,
            card.due.map(formatDate),
            card.stability,
            card.difficulty,
            card.lastSeen.map(formatDate),
            formatDate(card.createdAt),
            formatDate(card.updatedAt),
          ])
      }
    }
  }

  private func migrate() throws {
    var migrator = DatabaseMigrator()
    migrator.registerMigration("createMemoryCardIndex") { database in
      try database.execute(
        sql: """
          CREATE TABLE memory_cards (
            id TEXT PRIMARY KEY,
            display_title TEXT NOT NULL,
            body TEXT NOT NULL,
            file_path TEXT NOT NULL,
            directory TEXT NOT NULL,
            due TIMESTAMP,
            stability REAL,
            difficulty REAL,
            last_seen TIMESTAMP,
            created_at TIMESTAMP NOT NULL,
            updated_at TIMESTAMP NOT NULL
          );

          CREATE INDEX idx_memory_due ON memory_cards(due);
          CREATE INDEX idx_memory_directory ON memory_cards(directory);
          CREATE INDEX idx_memory_updated_at ON memory_cards(updated_at);
          """)
    }

    migrator.registerMigration("addDisplayTitleAndUpdatedAt") { database in
      let columnNames = try String.fetchAll(
        database,
        sql: "SELECT name FROM pragma_table_info('memory_cards')")

      if !columnNames.contains("display_title") {
        try database.execute(
          sql: "ALTER TABLE memory_cards ADD COLUMN display_title TEXT NOT NULL DEFAULT ''")
        if columnNames.contains("title") {
          try database.execute(sql: "UPDATE memory_cards SET display_title = title")
        }
      }

      if !columnNames.contains("updated_at") {
        try database.execute(sql: "ALTER TABLE memory_cards ADD COLUMN updated_at TIMESTAMP")
        try database.execute(sql: "UPDATE memory_cards SET updated_at = created_at")
      }

      try database.execute(
        sql: "CREATE INDEX IF NOT EXISTS idx_memory_updated_at ON memory_cards(updated_at)")
    }

    try migrator.migrate(dbQueue)
  }

  private func memoryCard(row: Row) -> MemoryCard {
    MemoryCard(
      id: row["id"],
      body: row["body"] ?? "",
      directory: row["directory"],
      due: parseDate(row["due"]),
      stability: row["stability"],
      difficulty: row["difficulty"],
      lastSeen: parseDate(row["last_seen"]),
      createdAt: parseDate(row["created_at"]) ?? Date(timeIntervalSince1970: 0),
      updatedAt: parseDate(row["updated_at"]) ?? Date(timeIntervalSince1970: 0))
  }

  private func formatDate(_ date: Date) -> String {
    dateFormatter(includingFractionalSeconds: true).string(from: date)
  }

  private func parseDate(_ value: String?) -> Date? {
    guard let value else {
      return nil
    }

    return dateFormatter(includingFractionalSeconds: true).date(from: value)
      ?? dateFormatter(includingFractionalSeconds: false).date(from: value)
  }

  private func dateFormatter(includingFractionalSeconds: Bool) -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions =
      includingFractionalSeconds
      ? [.withInternetDateTime, .withFractionalSeconds]
      : [.withInternetDateTime]
    return formatter
  }
}
