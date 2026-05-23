import Foundation
import Testing

@testable import Gacha

@Test func appSettingsDecodeCamelCaseKeys() throws {
  let data = Data(#"{"knowledgeAutoCollapseSeconds":45}"#.utf8)
  let settings = try JSONDecoder().decode(AppSettings.self, from: data)

  #expect(settings.knowledgeAutoCollapseSeconds == 45)
}

@Test func appSettingsEncodeCamelCaseKeys() throws {
  let settings = AppSettings(knowledgeAutoCollapseSeconds: 45)
  let data = try JSONEncoder().encode(settings)
  let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Double])

  #expect(object["knowledgeAutoCollapseSeconds"] == 45)
}
