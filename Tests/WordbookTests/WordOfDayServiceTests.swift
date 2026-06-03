import Foundation
import Testing
@testable import Wordbook

struct WordOfDayServiceTests {
    @Test
    func usesCachedEntryForSameDay() async throws {
        let cached = WordOfDayEntry(
            dateKey: "2026-06-03",
            entry: DictionaryEntry(
                word: "anchor",
                phonetic: nil,
                phonetics: [],
                meanings: [],
                sourceURLs: []
            )
        )

        let service = LiveWordOfDayService(
            dictionaryService: FailingDictionaryService(),
            calendar: Calendar(identifier: .gregorian),
            now: {
                var components = DateComponents()
                components.year = 2026
                components.month = 6
                components.day = 3
                return Calendar(identifier: .gregorian).date(from: components) ?? .now
            }
        )

        let result = try await service.currentWord(cached: cached)
        #expect(result == cached)
    }

    @Test
    func dayIndexIsStable() {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 3)) ?? .now
        let index = LiveWordOfDayService.wordIndex(for: date, calendar: calendar)
        #expect(index >= 0)
        #expect(index < LiveWordOfDayService.curatedWords.count)
    }
}

private struct FailingDictionaryService: DictionaryService {
    func lookup(word: String) async throws -> DictionaryEntry {
        throw DictionaryLookupError.serverError
    }
}
