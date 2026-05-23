import Testing

@testable import Gacha

@Test func appMetadataUsesExpectedNames() {
  #expect(AppMetadata.name == "Gacha")
  #expect(AppMetadata.bundleIdentifier == "com.iven.gacha")
  #expect(AppMetadata.knowledgeCardsDirectoryName == "Knowledge Cards")
}
