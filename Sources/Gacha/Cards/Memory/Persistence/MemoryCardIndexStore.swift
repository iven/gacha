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
          card.due.map(ISO8601Codec.format),
          card.stability,
          card.difficulty,
          card.lastSeen.map(ISO8601Codec.format),
          ISO8601Codec.format(card.createdAt),
          ISO8601Codec.format(card.updatedAt),
        ])
    }
  }

  func delete(id: String) throws {
    try dbQueue.write { database in
      try database.execute(sql: "DELETE FROM memory_cards WHERE id = ?", arguments: [id])
    }
  }

  func createDirectory(name: String) throws {
    try dbQueue.write { database in
      try database.execute(
        sql: "INSERT OR IGNORE INTO categories (name) VALUES (?)",
        arguments: [name])
    }
  }

  func deleteDirectory(name: String) throws {
    try dbQueue.write { database in
      try database.execute(
        sql: "DELETE FROM memory_cards WHERE directory = ?",
        arguments: [name])
      try database.execute(
        sql: "DELETE FROM categories WHERE name = ?",
        arguments: [name])
    }
  }

  func renameDirectory(from oldName: String, to newName: String) throws {
    try dbQueue.write { database in
      let rows = try Row.fetchAll(
        database,
        sql: "SELECT id, file_path FROM memory_cards WHERE directory = ?",
        arguments: [oldName])
      for row in rows {
        let id: String = row["id"]
        let oldFilePath: String = row["file_path"]
        let fileName = (oldFilePath as NSString).lastPathComponent
        let newFilePath = "\(newName)/\(fileName)"
        try database.execute(
          sql: """
            UPDATE memory_cards
            SET directory = ?, file_path = ?
            WHERE id = ?
            """,
          arguments: [newName, newFilePath, id])
      }
      try database.execute(
        sql: "UPDATE categories SET name = ? WHERE name = ?",
        arguments: [newName, oldName])
    }
  }

  func listDirectories() throws -> [String] {
    try dbQueue.read { database in
      try String.fetchAll(database, sql: "SELECT name FROM categories ORDER BY name")
    }
  }

  func categoryExists(_ name: String) throws -> Bool {
    try dbQueue.read { database in
      try Int.fetchOne(
        database,
        sql: "SELECT COUNT(*) FROM categories WHERE name = ?",
        arguments: [name]) ?? 0 > 0
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
    let directories = try repository.listDirectories()
    try dbQueue.write { database in
      try database.execute(sql: "DELETE FROM memory_cards")
      try database.execute(sql: "DELETE FROM categories")
      for directory in directories {
        try database.execute(
          sql: "INSERT INTO categories (name) VALUES (?)",
          arguments: [directory])
      }
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
            card.due.map(ISO8601Codec.format),
            card.stability,
            card.difficulty,
            card.lastSeen.map(ISO8601Codec.format),
            ISO8601Codec.format(card.createdAt),
            ISO8601Codec.format(card.updatedAt),
          ])
      }
    }
  }

  // MARK: - Private

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

    migrator.registerMigration("addCategoriesTable") { database in
      try database.execute(
        sql: """
          CREATE TABLE categories (
            name TEXT PRIMARY KEY
          );
          """)

      // Backfill from existing memory_cards
      try database.execute(
        sql: """
          INSERT OR IGNORE INTO categories (name)
          SELECT DISTINCT directory FROM memory_cards
          """)
    }

    try migrator.migrate(dbQueue)
  }

  private func memoryCard(row: Row) -> MemoryCard {
    let parse: (String?) -> Date? = { $0.flatMap(ISO8601Codec.parse) }
    return MemoryCard(
      id: row["id"],
      body: row["body"] ?? "",
      directory: row["directory"],
      due: parse(row["due"]),
      stability: row["stability"],
      difficulty: row["difficulty"],
      lastSeen: parse(row["last_seen"]),
      createdAt: parse(row["created_at"]) ?? Date(timeIntervalSince1970: 0),
      updatedAt: parse(row["updated_at"]) ?? Date(timeIntervalSince1970: 0))
  }
}
