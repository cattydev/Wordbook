import Foundation

protocol WordOfDayService: Sendable {
    func currentWord(cached: WordOfDayEntry?) async throws -> WordOfDayEntry
}

struct LiveWordOfDayService: WordOfDayService, Sendable {
    private let dictionaryService: any DictionaryService
    private let calendar: Calendar
    private let now: @Sendable () -> Date

    init(
        dictionaryService: any DictionaryService,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.dictionaryService = dictionaryService
        self.calendar = calendar
        self.now = now
    }

    func currentWord(cached: WordOfDayEntry?) async throws -> WordOfDayEntry {
        let currentDate = now()
        let key = Self.dateKey(for: currentDate, calendar: calendar)

        if let cached, cached.dateKey == key {
            return cached
        }

        let index = Self.wordIndex(for: currentDate, calendar: calendar)
        let lookupWord = Self.curatedWords[index]
        let entry = try await dictionaryService.lookup(word: lookupWord)
        return WordOfDayEntry(dateKey: key, entry: entry)
    }

    static func dateKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    static func wordIndex(for date: Date, calendar: Calendar) -> Int {
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? .distantPast
        let dayDelta = calendar.dateComponents([.day], from: start, to: date).day ?? 0
        return abs(dayDelta) % curatedWords.count
    }

    static let curatedWords = [
        "luminous", "curiosity", "resolute", "craft", "serene", "insight", "eloquent", "anchor",
        "brisk", "gather", "merit", "ornate", "kindred", "steady", "harbor", "lucid",
        "temper", "meadow", "hollow", "verge", "humble", "tactile", "fable", "glisten",
        "sincere", "ardent", "verdant", "wander", "murmur", "gentle", "ripple", "stanza",
        "clever", "solace", "forage", "thread", "mingle", "earnest", "fathom", "delight",
    ]
}
