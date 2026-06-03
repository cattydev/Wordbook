import Foundation
import Testing
@testable import Wordbook

struct DictionaryServiceTests {
    @Test
    func sanitizeRejectsInvalidCharacters() async throws {
        #expect(throws: DictionaryLookupError.invalidQuery) {
            try LiveDictionaryService.sanitize(word: "hello123")
        }
    }

    @Test
    func lookupBuildsNormalizedEntry() async throws {
        let json = """
        [{
          "word": "example",
          "phonetic": "/example/",
          "phonetics": [
            { "text": "/example/", "audio": "" },
            { "text": "/sample/", "audio": "https://example.com/audio.mp3" }
          ],
          "meanings": [{
            "partOfSpeech": "noun",
            "definitions": [{
              "definition": "A representative form.",
              "example": "This is an example.",
              "synonyms": ["illustration"],
              "antonyms": []
            }],
            "synonyms": ["specimen"]
          }],
          "sourceUrls": ["https://en.wiktionary.org/wiki/example"]
        }]
        """.data(using: .utf8)!

        let service = LiveDictionaryService { _ in
            (
                json,
                HTTPURLResponse(
                    url: URL(string: "https://dictionaryapi.dev/api/v2/entries/en/example")!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
            )
        }

        let normalized = try await service.lookup(word: "example")

        #expect(normalized.primaryAudioURL?.absoluteString == "https://example.com/audio.mp3")
        #expect(normalized.meanings.first?.definitions.first?.example == "This is an example.")
    }
}
