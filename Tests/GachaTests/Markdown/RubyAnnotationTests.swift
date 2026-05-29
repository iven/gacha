import AppKit
import CoreText
import Testing

@testable import Gacha

private let rubyKey = kCTRubyAnnotationAttributeName as NSAttributedString.Key

/// Collects (substring, hasRubyAnnotation) for each attribute run in the string.
private func rubyRuns(_ attributed: NSAttributedString) -> [(text: String, ruby: Bool)] {
  let nsString = attributed.string as NSString
  var runs: [(String, Bool)] = []
  attributed.enumerateAttribute(
    rubyKey, in: NSRange(location: 0, length: attributed.length)
  ) { value, range, _ in
    runs.append((nsString.substring(with: range), value != nil))
  }
  return runs
}

@Test func rubyGroupAnnotationCoversWholeBase() throws {
  let rendered = MarkdownContentRenderer(appearance: .light).render(markdown: "{東京|とうきょう}")
  let runs = rubyRuns(rendered).filter { !$0.text.isEmpty }

  // One run holding "東京" with a ruby annotation.
  let rubyRun = try #require(runs.first { $0.ruby })
  #expect(rubyRun.text == "東京")
  #expect(runs.filter { $0.ruby }.count == 1)
}

@Test func rubyMonoAnnotationSplitsPerCharacter() throws {
  let rendered = MarkdownContentRenderer(appearance: .light).render(markdown: "{東京|とう|きょう}")
  let rubyTexts = rubyRuns(rendered).filter { $0.ruby }.map(\.text)

  // Two separate annotated spans, one per character.
  #expect(rubyTexts == ["東", "京"])
}

@Test func rubyLastReadingTakesRemainingCharacters() throws {
  let rendered = MarkdownContentRenderer(appearance: .light).render(
    markdown: "{小夜時雨|さ|よ|しぐれ}")
  let rubyTexts = rubyRuns(rendered).filter { $0.ruby }.map(\.text)

  // 小=さ, 夜=よ, 時雨=しぐれ (last reading absorbs the remaining two chars).
  #expect(rubyTexts == ["小", "夜", "時雨"])
}

@Test func rubyAcceptsMiddleDotSeparator() throws {
  let rendered = MarkdownContentRenderer(appearance: .light).render(
    markdown: "{小夜時雨|さ・よ・しぐれ}")
  let rubyTexts = rubyRuns(rendered).filter { $0.ruby }.map(\.text)

  #expect(rubyTexts == ["小", "夜", "時雨"])
}

@Test func rubyFallsBackToGroupWhenReadingsExceedCharacters() throws {
  // Two characters, three readings — cannot distribute, so render as group ruby.
  let rendered = MarkdownContentRenderer(appearance: .light).render(markdown: "{東京|と|う|きょう}")
  let rubyRunsOnly = rubyRuns(rendered).filter { $0.ruby }

  #expect(rubyRunsOnly.count == 1)
  #expect(rubyRunsOnly.first?.text == "東京")
}

@Test func rubySkipsAnnotationWhenReadingEqualsKanaBase() throws {
  // Per-char reading where the kana annotates itself (れ→れ): that span renders
  // plain so it doesn't sit higher than the kanji annotations beside it.
  let rendered = MarkdownContentRenderer(appearance: .light).render(markdown: "{木漏れ日|こ|も|れ|び}")
  let runs = rubyRuns(rendered).filter { !$0.text.isEmpty }

  let kanjiWithRuby = runs.filter { $0.ruby }.map(\.text)
  #expect(kanjiWithRuby == ["木", "漏", "日"])
  // The kana れ is present but carries no ruby annotation.
  #expect(runs.contains { $0.text == "れ" && !$0.ruby })
}

@Test func plainTextHasNoRubyAnnotation() throws {
  let rendered = MarkdownContentRenderer(appearance: .light).render(markdown: "ただの文章")
  #expect(rubyRuns(rendered).allSatisfy { !$0.ruby })
}

@Test func rubyParagraphGetsRaisedLineHeight() throws {
  let rendered = MarkdownContentRenderer(appearance: .light).render(markdown: "私の{猫|ねこ}")
  let paragraphStyle = try #require(
    rendered.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)
  #expect(paragraphStyle.lineHeightMultiple > 1.0)
}

@Test func plainParagraphKeepsCompactLineHeight() throws {
  let rendered = MarkdownContentRenderer(appearance: .light).render(markdown: "普通の段落")
  let paragraphStyle = try #require(
    rendered.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)
  // No ruby → no raised line height.
  #expect(paragraphStyle.lineHeightMultiple == 0)
}
