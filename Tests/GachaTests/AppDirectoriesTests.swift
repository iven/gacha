import Foundation
import Testing

@testable import Gacha

@Test func appDirectoriesDescribeExpectedDirectoryTree() {
  let testRootURL = URL(fileURLWithPath: "/tmp/GachaTests")
  let directories = AppDirectories(
    applicationSupportURL: testRootURL.appendingPathComponent("Application Support"),
    userStorageURL: testRootURL.appendingPathComponent("Documents"))

  #expect(directories.applicationSupportURL.path == "/tmp/GachaTests/Application Support")
  #expect(directories.userStorageURL.path == "/tmp/GachaTests/Documents")
  #expect(directories.knowledgeCardsURL.lastPathComponent == "Knowledge Cards")
  #expect(directories.defaultKnowledgeCategoryURL.lastPathComponent == "Uncategorized")
}
